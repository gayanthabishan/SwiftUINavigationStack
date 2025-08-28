//
//  NavigationStackChildView.swift
//  PickMePassenger
//
//  Created by Bishan Meddegoda on 2025-07-02.
//  Copyright © 2025 PickMe Technologies. All rights reserved.
//
//  Description:
//  A lightweight wrapper view that delays rendering of its content,
//  typically used to avoid visual glitches during navigation transitions.
//  Helps ensure smoother push/pop animations by deferring UI updates
//  until the transition has completed.
//
/**
 ===================================================================
 Transition-Optimized View Loader:
 -------------------------------------------------------------------
 Utility view that delays rendering to ensure smooth push/pop transitions.
 Prevents rendering glitches during animation.
 ===================================================================

 Overview:
 Helps polish navigation animations in custom stacks.

 Responsibilities:
 - Defers view appearance using a configurable `delay`
 - Prevents premature layout during navigation transitions
 - Ideal for wrapping views pushed onto the stack
 - With the updated NavigationStackView keeping non-top screens mounted,
   this helper is optional in many screens. You can still use it on heavy
   detail screens (maps, large grids) to slightly defer layout until the
   push completes. Keep delays small for responsiveness.
 */

import SwiftUI

///// A wrapper that waits before showing its content, giving time for navigation animations to finish.
public struct NavigationStackChildView<Content: View>: View {
    private let delay: TimeInterval
    private let content: () -> Content

    @State private var shouldRender = false

    /// - Parameters:
    ///   - delay: Small delay to avoid competing with the transition (default 0.05s).
    ///   - content: The content view to load after the delay.
    public init(delay: TimeInterval = 0.25, @ViewBuilder content: @escaping () -> Content) {
        self.delay = delay
        self.content = content
    }

    public var body: some View {
        Group {
            if shouldRender {
                content()
            } else {
                Color.clear
            }
        }
        .onAppear {
            // Slight delay before content appears, to avoid overlapping with push transition.
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                shouldRender = true
            }
        }
    }
}
