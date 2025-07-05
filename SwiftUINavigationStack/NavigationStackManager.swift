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

import SwiftUI

/// Tracks whether you're moving forward or backward in navigation.
enum NavigationType {
    case push
    case pop
}

/// Tells the stack where to go when popping a view.
public enum PopDestination {
    /// Go back one step.
    case previous

    /// Jump  to the root screen.
    case root

    /// Go back to a view with a specific ID.
    case view(withId: String)
}

/**
 Controls how screens are stacked and switched.

 This is the engine behind `NavigationStackView`, and lets you handle navigation manually.

 It’s automatically available in any `NavigationStackView`, or you can pass it in yourself.
*/
public class NavigationStackManager: ObservableObject {

    /// Default speed and curve used when switching screens.
    public static let defaultEasing = Animation.easeOut(duration: 0.2)

    @Published var currentView: ViewElement?
    @Published private(set) var navigationType = NavigationType.push
    private let easing: Animation

    /// Sets up the stack manager with a default or custom animation speed.
    public init(easing: Animation = defaultEasing) {
        self.easing = easing
    }

    private var viewStack = ViewStack() {
        didSet {
            currentView = viewStack.peek()
        }
    }

    /// Shows how many screens are currently in the stack.
    public var depth: Int {
        viewStack.depth
    }

    /// Checks if a screen with a specific ID already exists in the stack.
    public func containsView(withId id: String) -> Bool {
        viewStack.indexForView(withId: id) != nil
    }

    /// Push a new screen onto the stack.
    public func push<Element: View>(_ element: Element, withId identifier: String? = nil) {
        navigationType = .push
        withAnimation(easing) {
            viewStack.push(ViewElement(id: identifier ?? UUID().uuidString,
                                       wrappedElement: AnyView(element)))
        }
    }

    /// Go back in the stack based on where you want to return.
    public func pop(to: PopDestination = .previous) {
        navigationType = .pop
        withAnimation(easing) {
            switch to {
            case .root:
                viewStack.popToRoot()
            case .view(let viewId):
                viewStack.popToView(withId: viewId)
            default:
                viewStack.popToPrevious()
            }
        }
    }
}


/// A lightweight stack that manages the order of screens.
private struct ViewStack {
    private var views = [ViewElement]()

    /// Returns the top view on the stack, if any.
    func peek() -> ViewElement? {
        views.last
    }

    /// Gives the total number of views in the stack.
    var depth: Int {
        views.count
    }

    /// Adds a new view to the top of the stack, if its ID isn’t already present.
    mutating func push(_ element: ViewElement) {
        guard indexForView(withId: element.id) == nil else {
            print("warning : view with id \"\(element.id)\" exists in the stack")
            return
        }
        views.append(element)
    }

    /// Removes just the last view from the stack.
    mutating func popToPrevious() {
        _ = views.popLast()
    }

    /// Pops views until the specified view ID is at the top.
    mutating func popToView(withId identifier: String) {
        guard let viewIndex = indexForView(withId: identifier) else {
            print("No view with the ID \"\(identifier)\".")
            return
        }
        views.removeLast(views.count - (viewIndex + 1))
    }

    /// Clears all views from the stack.
    mutating func popToRoot() {
        views.removeAll()
    }

    /// Looks up a view’s position in the stack by its ID.
    func indexForView(withId identifier: String) -> Int? {
        views.firstIndex {
            $0.id == identifier
        }
    }
}

/// A wrapper for any SwiftUI view that’s stored in the navigation stack.
struct ViewElement: Identifiable, Equatable {
    let id: String
    let wrappedElement: AnyView

    /// Two views are equal if their IDs match.
    static func == (lhs: ViewElement, rhs: ViewElement) -> Bool {
        lhs.id == rhs.id
    }
}
