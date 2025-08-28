//
//  NavigationStackDemo.swift
//  PickMePassenger
//
//  Created by Bishan Meddegoda on 2025-07-02.
//  Copyright © 2025 PickMe Technologies. All rights reserved.
//
//  Description:
//  A sample SwiftUI application that demonstrates the usage of the custom navigation stack.
//  Showcases navigation features including push, pop, pop to root, and pop to specific ID,
//  using NavigationStackManager, NavigationStackView, and NavigationStackChildView.
//

import SwiftUI

// MARK: - App Entry

public struct NavigationStackDemo: View {
    @StateObject private var navigationStack = NavigationStackManager()

    public init() {}

    public var body: some View {
        NavigationStackView(
            navigationStack: navigationStack,
            rootView: Group {
                HomeScreen()
            }
        )
        .environmentObject(navigationStack)
    }
}

// MARK: - Home Screen

struct HomeScreen: View {
    @EnvironmentObject var nav: NavigationStackManager

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                Text("🏠 Home Screen")
                    .font(.title)

                Button("Push First View") {
                    nav.push(FirstScreen(), withId: "FirstScreen")
                }

                Text("Stack depth: \(nav.depth)")
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - First Screen

struct FirstScreen: View {
    @EnvironmentObject var nav: NavigationStackManager

    var body: some View {
        NavigationStackChildView {
            ZStack {
                VStack(spacing: 16) {
                    Text("1️⃣ First Screen")
                        .font(.title)

                    Button("Push Second View") {
                        nav.push(SecondScreen(), withId: "SecondScreen")
                    }

                    Button("Back to Previous") {
                        nav.pop()
                    }

                    Text("Stack depth: \(nav.depth)")
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Second Screen

struct SecondScreen: View {
    @EnvironmentObject var nav: NavigationStackManager

    var body: some View {
        NavigationStackChildView {
            ZStack {
                VStack(spacing: 16) {
                    Text("2️⃣ Second Screen")
                        .font(.title)

                    Button("Push Final View") {
                        nav.push(FinalScreen(), withId: "FinalScreen")
                    }

                    Button("Back to First") {
                        nav.popToView(withId: "FirstScreen")
                    }

                    Button("Back to Previous") {
                        nav.pop()
                    }

                    Text("Stack depth: \(nav.depth)")
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Final Screen

struct FinalScreen: View {
    @EnvironmentObject var nav: NavigationStackManager

    var body: some View {
        NavigationStackChildView {
            ZStack {
                VStack(spacing: 16) {
                    Text("🏁 Final Screen")
                        .font(.title)

                    Button("Back to Root") {
                        nav.popToRoot()
                    }

                    Button("Back to First") {
                        nav.popToView(withId: "SecondScreen")
                    }

                    Button("Back to Second") {
                        nav.pop()
                    }

                    Text("Stack depth: \(nav.depth)")
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                print("Current stack depth: \(nav.depth)")
                print("Stack contains 'FirstScreen'? \(nav.containsView(withId: "FirstScreen"))")
            }
        }
    }
}
