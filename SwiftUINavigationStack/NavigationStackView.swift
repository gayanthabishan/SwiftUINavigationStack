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
    public init(transitionType: NavigationTransition = .default,
                easing: Animation = NavigationStackManager.defaultEasing,
                @ViewBuilder rootView: () -> Root) {

        self.init(transitionType: transitionType,
                  navigationStack: NavigationStackManager(easing: easing),
                  rootView: rootView)
    }

    /// Initialize using your own stack manager instance.
    public init(transitionType: NavigationTransition = .default,
                navigationStack: NavigationStackManager,
                @ViewBuilder rootView: () -> Root) {

        self.rootView = rootView()
        self.navigationStack = navigationStack
        switch transitionType {
        case .none:
            self.transitions = (.identity, .identity)
        case .custom(let trans):
            self.transitions = (trans, trans)
        default:
            self.transitions = NavigationTransition.defaultTransitions
        }
    }

    public var body: some View {
        let showRoot = navigationStack.currentView == nil
        let navigationType = navigationStack.navigationType

        return ZStack {
            if showRoot {
                rootView
                    .transition(navigationType == .push ? transitions.push : transitions.pop)
                    .environmentObject(navigationStack)
            } else {
                navigationStack.currentView!.build()
                    .transition(navigationType == .push ? transitions.push : transitions.pop)
                    .environmentObject(navigationStack)
            }
        }
    }
}

