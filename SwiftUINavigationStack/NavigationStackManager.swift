//
//  NavigationStackManager.swift
//  PickMePassenger
//
//  Created by Bishan Meddegoda on 2025-07-01.
//  Copyright © 2025 PickMe Technologies. All rights reserved.
//
//  Description:
//  Acts as the central controller for managing a custom navigation stack.
//  Handles the logic for pushing and popping views, tracking navigation depth,
//  and applying animated transitions. Works in conjunction with NavigationStackView
//  to provide a fully programmatic and customizable navigation experience.
//
/**
 ===================================================================
 Core Navigation Engine:
 -------------------------------------------------------------------
 This file defines the central logic for managing a custom navigation stack.
 Changes here will affect all stack-based navigation behaviors.
 Proceed with caution.
 ===================================================================

 Overview:
 A core component of the custom SwiftUI navigation system.

 Responsibilities:
 - Manages  internal LIFO stack of views using `ViewElement`
 - Provides push, pop, replace, and popToRoot operations
 - Tracks direction of navigation via `NavigationType`
 - Applies smooth animated transitions using custom easing
 - Serves as the data source for `NavigationStackView`
 -
    * Exposes a read-only snapshot of the *entire* stack so
      NavigationStackView can render all screens at once and only
      fade/hit-test the top. This mirrors UINavigationController’s
      “keep view controllers alive” behavior to avoid UI re-renders
      and scroll resets on pop.
 */

import SwiftUI

/// Direction of the last navigation operation. Used to pick push vs pop transitions.
public enum NavigationType {
    case push
    case pop
}

/// High-level navigation targets (kept for completeness; you may already be using this).
public enum NavigationTarget {
    /// Go back one screen.
    case previous
    /// Jump  to the root screen.
    case root
    /// Go back to a view with a specific ID.
    case view(withId: String)
}

/// Central observable object driving the custom navigation.
public final class NavigationStackManager: ObservableObject {

    // MARK: - Published state

    /// The element currently visible on top of the stack (nil == root).
    @Published public private(set) var currentView: ViewElement? = nil

    /// The last navigation direction (.push / .pop) to drive transitions.
    @Published public private(set) var navigationType: NavigationType = .push
    
    /// Default speed and curve used when switching screens.
    public var animation: Animation { Animation.easeInOut(duration: 0.35) }

    // NOTE: We purposely keep the underlying stack private and immutable from outside
    // to guarantee invariants and avoid accidental mutations.
    private var viewStack = ViewStack() {
        didSet {
            // Keep published state in sync.
            self.currentView = viewStack.peek()
            // (We do not publish the whole array here to preserve the existing API surface.
            //  The view layer fetches a snapshot via allStackedViews() when needed.)
        }
    }

    /// Push a new view on top of the stack.
    @MainActor
    public func push<V: View>(_ view: V, withId identifier: String? = nil) {
        navigationType = .push
        let id = identifier ?? UUID().uuidString
        let element = ViewElement(id: id) { AnyView(view) }
        
        withAnimation(animation) {
            viewStack.push(element)
            objectWillChange.send()
        }
    }

    /// Replace the current top view with another (does not change stack depth).
    @MainActor
    public func replace<V: View>(_ view: V, withId identifier: String? = nil) {
        navigationType = .push
        let id = identifier ?? UUID().uuidString
        let element = ViewElement(id: id) { AnyView(view) }
        withAnimation(animation) {
            viewStack.replaceTop(with: element)
            objectWillChange.send()
        }
    }

    /// Pop back a single level if possible.
    @MainActor
    public func pop(withAnimation animate: Bool = true) {
        guard !viewStack.isEmpty else { return }
        navigationType = .pop
        let mutate = {
            _ = self.viewStack.popLast()
            self.objectWillChange.send()
        }
        if animate {
            withAnimation(animation) { mutate() }
        } else {
            mutate()
        }
    }

    /// Pop all the way back to root.
    @MainActor
    public func popToRoot(withAnimation animate: Bool = true) {
        guard !viewStack.isEmpty else { return }
        navigationType = .pop
        let mutate = {
            self.viewStack.removeAll()
            self.objectWillChange.send()
        }
        if animate {
            withAnimation(animation) { mutate() }
        } else {
            mutate()
        }
    }

    /// Pop back to a specific view id if it exists in the stack.
    @MainActor
    public func popToView(withId id: String, withAnimation animate: Bool = true) {
        guard viewStack.contains(id: id) else { return }
        navigationType = .pop
        let mutate = {
            self.viewStack.removeUntil(including: id)
            self.objectWillChange.send()
        }
        if animate {
            withAnimation(animation) { mutate() }
        } else {
            mutate()
        }
    }
    
    /// Remove *all* views from the stack and drop hooks/resources.
    @MainActor
    public func resetAll() {
        navigationType = .pop
        viewStack.removeAll()
        currentView = nil
        objectWillChange.send()
    }

    /// Current depth (0 means root currently visible).
    public var depth: Int { viewStack.count }
    
    /// Checks if a screen with a specific ID already exists in the stack.
    public func containsView(withId id: String) -> Bool {
        allStackedViews().contains { $0.id == id }
    }

    /**
     Returns a read-only snapshot of the *entire* stack, from bottom to top.
     - The view layer (NavigationStackView) uses this to render all screens at once,
       keeping non-top screens mounted to preserve scroll offsets and local state.
     - We intentionally return a fresh array to avoid exposing internal mutability.
     */
    public func allStackedViews() -> [ViewElement] {
        viewStack.viewsSnapshot()
    }
}

// MARK: - Internal LIFO container

private struct ViewStack {
    private var views: [ViewElement] = []

    var count: Int { views.count }
    var isEmpty: Bool { views.isEmpty }

    func peek() -> ViewElement? { views.last }

    mutating func push(_ view: ViewElement) {
        views.append(view)
    }

    mutating func replaceTop(with view: ViewElement) {
        if !views.isEmpty {
            _ = views.popLast()
        }
        views.append(view)
    }

    mutating func removeAll() { views.removeAll() }

    func contains(id: String) -> Bool {
        views.contains(where: { $0.id == id })
    }

    /// Removes elements until `id` is on top (inclusive).
    mutating func removeUntil(including id: String) {
        if let index = views.lastIndex(where: { $0.id == id }) {
            views.removeSubrange(index..<views.endIndex)
        }
    }

    /// Removes and returns the top view from the stack, if any.
    mutating func popLast() -> ViewElement? {
        return views.popLast()
    }
    
    /// Returns a copy of the current stack (bottom..top). Non-mutating.
    func viewsSnapshot() -> [ViewElement] { views }
}

///// A wrapper for any SwiftUI view that’s stored in the navigation stack.
public struct ViewElement: Identifiable, Equatable {
    public let id: String
    public let build: () -> AnyView
    public static func == (lhs: ViewElement, rhs: ViewElement) -> Bool {
        lhs.id == rhs.id
    }

    // Convenience init to keep call sites tidy.
    public init(id: String, build: @escaping () -> AnyView) {
        self.id = id
        self.build = build
    }
}

