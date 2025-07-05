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

import SwiftUI

/// A wrapper that waits before showing its content, giving time for navigation animations to finish.
struct NavigationStackChildView<Content: View>: View {
    @EnvironmentObject private var navigationStack: NavigationStackManager
    @State private var shouldRender = false

    let delay: TimeInterval
    let content: () -> Content

    /// Create a view that shows its content after a short wait (default is 0.25s).
    init(
        delay: TimeInterval = 0.25,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.delay = delay
        self.content = content
    }

    var body: some View {
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
