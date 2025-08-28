//
//  NavigationStackView.swift
//  PickMePassenger
//
//  Created by Bishan Meddegoda on 2025-07-01.
//  Copyright © 2025 PickMe Technologies. All rights reserved.
//
//  Description:
//  A custom SwiftUI container that manages navigation using a stack-based approach.
//  It allows for full control over push/pop transitions, animated navigation,
//  and programmatic view stacking, providing a more flexible alternative
//  to SwiftUI's native NavigationStack.
//
/**
 ===================================================================
 Custom Navigation Container:
 -------------------------------------------------------------------
 Defines the container that renders the root view and handles navigation stack.
 Used to replace SwiftUI's built-in NavigationStack with more flexibility.
 ===================================================================

 Overview:
 A SwiftUI container view that manages programmatic navigation.

 Responsibilities:
 - Hosts your root screen and any number of pushed screens.
 - Applies asymmetric transitions for push/pop.
 - Works with NavigationStackManager to mutate the stack.

   * Renders **all** stacked screens concurrently in a ZStack and only
     makes the top screen visible/hit-testable. This keeps non-top
     screens **mounted** so their local state (e.g., scroll position)
     is preserved when you pop back, mirroring NavigationLink behavior.
 */

import SwiftUI

/// Different types of transitions that control how screens animate.
public enum NavigationTransition {
    /// No animation between screens.
    case none

    /// Use the system’s default animation style.
    case `default`

    /// Provide a custom animation transition.
    case custom(AnyTransition)

    /// Default behavior: push slides in from right, pop slides in from left.
    public static var defaultTransitions: (push: AnyTransition, pop: AnyTransition) {
        let pushTrans = AnyTransition.asymmetric(insertion: .move(edge: .trailing),
                                                 removal: .move(edge: .leading))
        let popTrans = AnyTransition.asymmetric(insertion: .move(edge: .leading),
                                                removal: .move(edge: .trailing))
        return (pushTrans, popTrans)
    }
}

/// A custom view stack for navigation, offering better control over how screens transition and appear.
public struct NavigationStackView<Root>: View where Root: View {
    @ObservedObject private var navigationStack: NavigationStackManager
    private let rootView: Root
    private let transitions: (push: AnyTransition, pop: AnyTransition)

    /// Initialize the view stack with a starting screen and animation style.
    /// - Parameters:
    ///   - navigationStack: The shared manager controlling the stack.
    ///   - rootView: The root screen to show when stack is empty.
    ///   - transitions: Pair of transitions used for push and pop.
    public init(
        navigationStack: NavigationStackManager,
        rootView: Root,
        transitions: (push: AnyTransition, pop: AnyTransition) = NavigationTransition.defaultTransitions
    ) {
        self.navigationStack = navigationStack
        self.rootView = rootView
        self.transitions = transitions
    }

    public var body: some View {
        // Snapshot stack info
        let views = navigationStack.allStackedViews()      // bottom..top (root is implicit at index 0)
        let topIndex = views.count                         // root = 0, first push = 1, etc.
        let navType = navigationStack.navigationType

        return GeometryReader { proxy in
            let width = proxy.size.width

            ZStack(alignment: .leading) {
                // Root (index 0): always mounted
                rootView
                    .id("nav-root")
                    .frame(width: width, alignment: .leading)
                    .offset(x: CGFloat(0 - topIndex) * width)         // slide with stack
                    .allowsHitTesting(topIndex == 0)
                    .zIndex(0)
                    .environmentObject(navigationStack)

                // Pushed views (indices 1...top)
                ForEach(Array(views.enumerated()), id: \.element.id) { index, element in
                    let stackIndex = index + 1                        // shift because root is 0
                    element.build()
                        .id(element.id)
                        .frame(width: width, alignment: .leading)
                        .offset(x: CGFloat(stackIndex - topIndex) * width) // slide with stack
                        .allowsHitTesting(stackIndex == topIndex)
                        .zIndex(Double(stackIndex))
                        .environmentObject(navigationStack)
                }
            }
            // IMPORTANT: animate property changes (offsets) with the same easing used by the manager.
            // Tying the value to both depth and nav direction ensures a fresh animation each time.
            .animation(navigationStack.animation, value: topIndex)
            .animation(navigationStack.animation, value: navType)
        }
    }
}
