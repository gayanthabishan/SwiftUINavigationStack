# SwiftUINavigationStack

A lightweight, reusable custom navigation system built for **SwiftUI** that offers full control over navigation transitions, stack management, and state restoration — while resolving many of the core limitations of SwiftUI’s built-in `NavigationStack`.

---

## What is SwiftUINavigationStack?

`SwiftUINavigationStack` is a custom implementation of a navigation stack for SwiftUI apps. It mirrors the push/pop behavior of UIKit's `UINavigationController`, but is:

- State-driven
- View-based
- Type-safe
- Non-intrusive

It allows fine-grained control over navigation flow — something that's hard to achieve with `NavigationLink` or SwiftUI’s native `NavigationStack`, especially in more complex use cases.

---

## Why Not Use SwiftUI's NavigationStack?

While SwiftUI’s native `NavigationStack` (iOS 16+) looks promising, it suffers from real-world limitations:

| Limitation | Problem |
|-----------|---------|
| Poor control over deep stacks | Hard to push/pop programmatically across nested views |
| No `.popToRoot()` support | Can't reset the navigation stack |
| Buggy transitions | Views jump or behave unexpectedly during animations |
| No navigation state tracking | Can't know the current depth, view ID, or navigation history |
| View recreation issues | NavigationLink often re-creates views unnecessarily |

---

## What Problems This Solves

This custom navigation stack:

- Supports push/pop navigation with custom `push()` and `pop()` methods
- Enables pop to root and pop to view with ID
- Offers full stack depth tracking
- Allows navigation control from view models
- Prevents bugs from using multiple `NavigationLink`s
- Makes animated transitions predictable and smoother
- Supports deep linking and conditional navigation

---

## Architecture Overview

- `NavigationStackManager`: Stores the navigation stack and exposes push/pop methods
- `NavigationStackView`: Root view that renders the current stack
- `NavigationStackChildView`: A wrapper that applies entry/exit transitions to views
- `ViewElement`: A wrapper for pushed `AnyView`s with an identifier
- `Push/Pop Helpers`: Type-safe convenience methods for navigation

---

## Example Usage

```swift
NavigationStackView {
    HomeView()
}
```

From a child view:

```swift
@EnvironmentObject var navigationStack: NavigationStackManager

Button("Go to Details") {
    navigationStack.push(DetailsView(), withId: "DetailsView")
}
```

Pop to root:

```swift
navigationStack.popToRoot()
```

Pop to specific view:

```swift
navigationStack.pop(to: .view(withId: "HomeView"))
```

---

## When to Use This

Use this if your app:

- Has complex, multi-screen navigation
- Needs precise stack control (like a booking or checkout flow)
- Requires programmatic navigation from view models
- Needs a stable and smooth alternative to `NavigationLink`
- Wants reusable navigation infrastructure across modules

---

## Folder Structure

```
SwiftUINavigationStack/
├── NavigationStackView.swift
├── NavigationStackManager.swift
├── NavigationStackChildView.swift
├── ViewElement.swift
├── PushPopHelpers.swift
```

---

## Requirements

- iOS 14+
- Swift 5.5+
- SwiftUI

---

## Installation

### Option 1: Git Submodule

```bash
git submodule add https://github.com/yourusername/SwiftUINavigationStack.git Modules/NavigationStack
```

Then drag the `NavigationStack` files into your Xcode project.

### Option 2: Manual

Just copy the files from this repo into your SwiftUI app.

---

## Sample Project

A sample `DemoApp` is included to test:

- Pushing views
- Popping to root
- Deep linking
- Animations
- Shimmer loading and transitions

---

## Credits

Created and maintained by [@gayanthabishan](https://github.com/gayanthabishan)

---


---

## NavigationStackChildView

`NavigationStackChildView` is a lightweight wrapper used to **defer rendering of its content** until after a short delay (default: 0.25 seconds). It’s particularly useful when pushing a new view to the stack, helping to ensure smoother navigation transitions.

### Why This Is Important

When a new view is pushed, SwiftUI sometimes renders shimmer views or content **before the navigation transition completes**, causing awkward UI jumps or layout flashes. This wrapper fixes that.

### Key Benefits

- Prevents shimmer views from appearing under or over navigation animations
- Delays rendering to avoid layout jumps during transitions
- Helps keep navigation experience visually clean and polished
- Automatically used as a wrapper for all views inside `NavigationStackView`

### Usage

```swift
NavigationStackChildView {
    EventDetailsView()
}
```

You typically won’t need to use this manually — it's already applied internally by the navigation stack when pushing new views.



---

## Components Included

### 1. NavigationStackView
A container that manages view transitions and stack behavior. It serves as the entry point for using the custom navigation system. Handles animated transitions, view stacking, and environment propagation.

**Key Features**
- Animated push/pop navigation
- Transition customization
- Works as a root container

---

### 2. NavigationStackManager
A state controller that tracks and manages the navigation stack. It offers methods to push, pop, and pop to root or specific views.

**Key Features**
- Stack-based navigation control
- Push/pop logic
- Tracks stack depth and navigation type

---

### 3. NavigationStackChildView
A wrapper that defers rendering of its content by a short duration (default: 0.25s). Prevents UI glitches when transitions are in progress.

**Why Use It**
- Avoids visual glitches during push/pop
- Improves UX by rendering after transition completes
- Automatically used inside the stack (no manual usage required in most cases)

```swift
NavigationStackChildView {
    EventDetailsView()
}
```

---

These components work together to provide a predictable and flexible alternative to SwiftUI’s built-in `NavigationStack`.


## License

This project is open-source under the MIT License. See `LICENSE` for details.
