# FloatingPanelKit — Design & Implementation Spec

A cross-platform (iOS / iPadOS / macOS) SwiftUI package that recreates the
floating panel + map-overlay-button system used in Apple Maps.

---

## 1. Design Goals

- One shared component tree, adaptive layout per platform (not three separate implementations).
- Visual language matches system "floating chrome": `.ultraThinMaterial` / `.regularMaterial`, continuous corner radius, soft shadow, safe-area-aware placement.
- Panel behavior differs by idiom:
  - **iOS (iPhone):** bottom sheet, drag-from-top-edge, detents from "minimized" to "full screen."
  - **iPadOS / macOS:** anchored top-left "inspector" panel, drag-to-resize vertically.
- A **temporary taskbar** component shares the same chrome and appears contextually, positioned differently per platform.
- Everything is exposed through a small, opinionated public API — configuration structs and view modifiers, not subclassing.

---

## 2. Visual Language (shared tokens)

Define once, reused by every floating surface (panel, taskbar, map buttons):

| Token | Value (suggested) |
|---|---|
| `cornerRadius` | 16pt (panel/taskbar), continuous style |
| `buttonCornerRadius` | full circle, 44pt diameter |
| `material` | `.regularMaterial` (panel), `.ultraThinMaterial` (map buttons) |
| `shadow` | radius 8, y-offset 2, opacity 0.15 |
| `edgeMargin` | 12pt from safe area on iPhone, 16pt on iPad/Mac |
| `dragHandle` | 36×5pt capsule, `.tertiaryLabel`, only on iOS bottom sheet |
| `animation` | `.spring(response: 0.4, dampingFraction: 0.85)` for all detent/resize transitions |

Ship these as a `FloatingChromeStyle` struct so consumers can theme the whole package in one place (color, material, radius, shadow) rather than per-component.

---

## 3. Component Inventory

1. **`FloatingPanel`** — the tabbed container (main sheet/inspector).
2. **`FloatingPanelTabBar`** — bottom-pinned tab bar inside the panel (icon + label, Maps-style).
3. **`MapOverlayButtonStack`** — vertical stack of circular buttons, top-right over the map (location, style picker, extensible for more).
4. **`PanelVisibilityToggle`** — the show/hide button, top-right, independent of the button stack (or optionally merged into it — see §6).
5. **`TemporaryTaskbar`** — transient, same chrome, low height, platform-dependent placement.
6. **`FloatingPanelContainer`** — the top-level view that composes all of the above over your map content; this is what a consumer actually drops into their app.

---

## 4. Layout Behavior

### 4.1 iOS (iPhone) — Bottom Sheet

- Anchored to bottom edge, full device width minus `edgeMargin` (or edge-to-edge, matching Maps — recommend edge-to-edge with only top corners rounded).
- **Detents** (customizable, but ship defaults):
  - `.minimized` — just the tab bar + a sliver of content (~120pt), used when a taskbar needs room.
  - `.half` — ~50% of screen height (default resting state).
  - `.full` — expands to cover the full screen (top safe area inset only).
- Drag gesture recognized on the drag handle **and** the top ~24pt of panel content, so users can drag from the top edge as requested. Use `DragGesture(minimumDistance: 2)` combined with velocity-based detent snapping (mirror `UISheetPresentationController` feel: fast flick commits to next detent even if drag distance is short).
- Tab bar stays pinned at the bottom of the panel at all detents (like Maps' "Search/Favorites/..." row).
- Underlying map content should inset its bottom padding to `.minimized` height so map controls/annotations aren't obscured at rest — expose this as a published height value (see §6.3).

### 4.2 iPadOS / macOS — Floating Corner Panel

- Anchored top-left, fixed width (e.g., 320–380pt, configurable), NOT full height by default.
- Vertically resizable via a drag handle on the **bottom edge** of the panel (cursor becomes resize cursor on macOS via `.onHover` + `NSCursor.resizeUpDown`).
- Min/max height configurable; default min ≈ tab bar + one row of content, max ≈ window height minus top/bottom margins.
- Tab bar pinned at the bottom of the panel, consistent with iOS (unlike typical Mac sidebars, this intentionally matches Maps' cross-platform tab placement).
- Panel floats over the map content; it does not push/resize the map (it's an overlay, not a split view).

### 4.3 Idiom Detection

Don't rely purely on horizontal size class — iPad can be "regular" in split view but should still use the corner-panel layout, not the iPhone sheet. Detect explicitly:

```swift
enum PanelLayoutMode {
    case bottomSheet   // iPhone
    case floatingCorner // iPad, Mac
}
```

Resolve via `UIDevice.current.userInterfaceIdiom` (iOS/iPadOS) / always `.floatingCorner` on macOS, but allow the consumer to **override** via the config (useful for CarPlay-style edge cases, or if they want iPad to use the phone sheet in compact width).

---

## 5. Temporary Taskbar

- Same `FloatingChromeStyle` as the panel (material, radius, shadow) — reads as a sibling surface, not a separate UI language.
- Fixed small height (e.g., 44–56pt), horizontally sized to content or matched to panel width per platform rule below.
- **iOS:** when taskbar is shown, panel auto-transitions to `.minimized` detent. Taskbar appears directly above the panel, same horizontal width and edge alignment as the panel, small gap (~8pt) between them. Both move together as a coordinated group — treat this as one compound "bottom stack" during layout, not two independently-positioned views.
- **iPadOS / macOS:** taskbar appears top-right of the window, independent of the panel (which stays top-left). Does not affect panel size/position at all on these platforms.
- Presentation is driven by the consumer (`isPresented: Bool` binding) — the package does not auto-decide *when* to show it, only *how* and *where*.

---

## 6. Public API Contract

Keep the surface small: a handful of config structs + one container view + a couple of environment-style modifiers. Consumer should be able to get a working Maps-like shell in ~20 lines, and override styling/detents without touching internals.

### 6.1 Core API — view modifier, not a container

The package is **content-agnostic**: it doesn't own or wrap your map view. It's a modifier you attach to whatever full-bleed content you already have (map, custom renderer, anything). This keeps adoption to "add one modifier" rather than "restructure your view hierarchy around our container."

```swift
public extension View {
    func floatingPanel<Content: View>(
        configuration: FloatingPanelConfiguration = .default,
        tabs: [FloatingPanelTab],
        selection: Binding<FloatingPanelTab.ID>,
        isPanelVisible: Binding<Bool> = .constant(true),
        taskbar: TemporaryTaskbarContent? = nil, // nil = not shown
        @ViewBuilder content: @escaping (FloatingPanelTab.ID) -> Content
    ) -> some View
}
```

Usage:

```swift
MyMapView()
    .floatingPanel(tabs: tabs, selection: $selectedTab, content: { id in TabBody(id) })
```

- Internally implemented as a `ViewModifier` that overlays the panel/tab bar/buttons/taskbar chrome on top of `self` (the map), and injects the environment insets described in §6.6 into `self`'s subtree.
- The modifier resolves `.bottomSheet` vs `.floatingCorner` internally — no platform-conditional code required from the consumer.
- Because the map is never re-parented into a package-owned container, the consumer keeps full control over their view hierarchy, state, and any other modifiers they've already applied to it.

### 6.2 Configuration

```swift
public struct FloatingPanelConfiguration {
    public var style: FloatingChromeStyle = .default
    public var layoutModeOverride: PanelLayoutMode? = nil
    public var detents: [FloatingPanelDetent] = FloatingPanelDetent.defaultSet // iOS only
    public var cornerPanelWidth: CGFloat = 340        // iPad/Mac
    public var cornerPanelHeightRange: ClosedRange<CGFloat> = 160...600
    public var edgeMargin: CGFloat = 16
    public var showsMapOverlayButtons: Bool = true
    public var mapOverlayButtons: [MapOverlayButtonKind] = [.userLocation, .mapStyle]
}

public struct FloatingChromeStyle {
    public var material: Material
    public var cornerRadius: CGFloat
    public var shadowRadius: CGFloat
    public var shadowOpacity: Double
    public static let `default`: FloatingChromeStyle
}
```

### 6.3 Map overlay buttons

```swift
public enum MapOverlayButtonKind {
    case userLocation
    case mapStyle
    case custom(id: String, systemImage: String, action: () -> Void)
}
```

Ship `.userLocation` and `.mapStyle` as callbacks the consumer supplies (the package shouldn't own CoreLocation or MapKit style state):

```swift
public struct FloatingPanelActions {
    public var onUserLocationTapped: () -> Void
    public var onMapStyleTapped: () -> Void
}
```

Passed via an environment-style modifier or as a container init parameter — either is fine, but pick one and be consistent (recommend init parameter for discoverability).

### 6.4 Tabs

```swift
public struct FloatingPanelTab: Identifiable {
    public let id: String
    public let title: String
    public let systemImage: String
}
```

### 6.5 Detents (iOS)

```swift
public struct FloatingPanelDetent: Equatable {
    public static let minimized = FloatingPanelDetent(fraction: 0.12)
    public static let half = FloatingPanelDetent(fraction: 0.5)
    public static let full = FloatingPanelDetent(fraction: 0.98)
    public static let defaultSet = [minimized, half, full]

    public let fraction: CGFloat // of screen height
    public init(fraction: CGFloat)
}
```

### 6.6 Content awareness of panel insets

Two layers, primary + advanced, so simple consumers get a one-liner and advanced consumers can get exact geometry.

**Primary: environment value (recommended default).** The `.floatingPanel(...)` modifier injects the current effective inset into the environment of the content it's attached to (and everything nested inside it — annotation views, custom overlay controls, etc.), the same way SwiftUI publishes safe area information internally.

```swift
public struct FloatingPanelInsetsKey: EnvironmentKey {
    public static let defaultValue: EdgeInsets = EdgeInsets()
}

public extension EnvironmentValues {
    var floatingPanelInsets: EdgeInsets { get set }
}
```

- On iOS, this is a **bottom** inset tracking the sheet's current detent (updates live during drag).
- On iPadOS/macOS, this is a **leading (left)** inset tracking the corner panel's current width/height footprint.
- `EdgeInsets` naturally generalizes both cases (unused edges are zero) so consumers don't need platform branches to read it — one property, always correct for the current platform.
- Updates continuously during interactive drag/resize so map content (attribution, compass, controls) can track smoothly. This is intentional, not a corner case to special-case around.

```swift
struct MyMapContent: View {
    @Environment(\.floatingPanelInsets) private var panelInsets
    var body: some View {
        MapReader { proxy in
            Map()
                .safeAreaPadding(panelInsets) // or feed into a native inset API
        }
    }
}
```

**Advanced (opt-in): raw frame via PreferenceKey.** For consumers who need an exact `CGRect` — e.g. to feed MapKit's own `layoutMargins`/inset APIs rather than SwiftUI padding — expose the underlying frame as a preference key as well:

```swift
public struct FloatingPanelGeometryKey: PreferenceKey {
    public static var defaultValue: CGRect = .zero
    public static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}
```

Read via `.onPreferenceChange(FloatingPanelGeometryKey.self)`. Most consumers should never need this — it exists specifically for bridging into non-SwiftUI inset APIs. Document the environment value as the default path and this as the escape hatch, so the common case stays a one-liner.

### 6.7 Temporary taskbar

```swift
public struct TemporaryTaskbarContent {
    public let id: String
    public var content: AnyView
    public init<V: View>(id: String, @ViewBuilder content: () -> V)
}
```

Passed into `FloatingPanelContainer(taskbar:)`; presence/absence (nil vs non-nil) drives show/hide, with the container animating the transition and (on iOS) coordinating the panel's forced `.minimized` collapse automatically.

---

## 7. Suggested Package Structure

```
FloatingPanelKit/
  Sources/FloatingPanelKit/
    Core/
      FloatingPanelConfiguration.swift
      FloatingChromeStyle.swift
      FloatingPanelDetent.swift
      PanelLayoutMode.swift
    Views/
      FloatingPanelModifier.swift         // public entry point (`.floatingPanel(...)`)
      FloatingPanel.swift                 // bottom sheet / corner panel switcher
      BottomSheetPanel.swift              // iOS-specific layout + drag logic
      FloatingCornerPanel.swift           // iPad/Mac-specific layout + resize logic
      FloatingPanelTabBar.swift
      MapOverlayButtonStack.swift
      PanelVisibilityToggle.swift
      TemporaryTaskbar.swift
    Modifiers/
      FloatingPanelGeometryReader.swift
    Support/
      PlatformIdiom.swift                 // resolves PanelLayoutMode
  Tests/FloatingPanelKitTests/
  Package.swift
```

- `BottomSheetPanel` and `FloatingCornerPanel` are internal — `FloatingPanel` picks between them based on resolved `PanelLayoutMode` and presents a single API outward.
- Keep MapKit/CoreLocation entirely out of the package; it only renders chrome and reports intents (button taps) via closures. This makes it reusable for non-MapKit map SDKs too.

---

## 8. Implementation Notes for the Coding Model

- Use `GeometryReader` at the `FloatingPanelContainer` level once, pass resolved size down — avoid nested `GeometryReader`s causing layout thrash.
- Bottom sheet drag: track a `@GestureState` offset, compute nearest detent by both **position** and **projected velocity** (`predictedEndLocation`), not just release position — this is what makes Apple's sheets feel right.
- Corner panel resize on macOS: back the drag handle with `.onHover { NSCursor.resizeUpDown.set() }` guarded by `#if os(macOS)`; on iPadOS use a plain drag gesture (no cursor).
- All platform-conditional code should live in the two internal panel implementations (`BottomSheetPanel` / `FloatingCornerPanel`), never leak into consumer-facing API — the whole point of the package is the consumer writes zero `#if os()` in their app.
- Respect safe areas explicitly (`.ignoresSafeArea()` on the map layer only; panel/buttons should stay within safe area insets).
- Taskbar/panel coordination on iOS (forcing `.minimized` when taskbar appears) should be a single derived state, not two independent animations racing each other — compute target frames for both surfaces in one pass per state change.
- Make `FloatingPanelTab.id` generic-friendly later if needed (currently `String`) but ship with `String` for simplicity/coding-model-friendliness.
- `floatingPanelInsets` should be driven by the same `@GestureState`/animation values used to lay out the panel itself — compute inset once per state change and inject via `.environment(\.floatingPanelInsets, value)` on the wrapped content, rather than recomputing independently. This keeps map content perfectly in sync with the visible panel edge, including mid-drag.
- Since the modifier no longer owns the map's parent view, it needs its own `GeometryReader` sized to `self` (the content it's attached to) to compute absolute detent heights / corner panel bounds — apply this inside the modifier's `body(content:)`, not in the public-facing API surface.

---

## 9. Open Decisions to Confirm Before Implementation

- Should `PanelVisibilityToggle` live inside `MapOverlayButtonStack` (as the top button) or be visually separate? Maps keeps it separate-ish but adjacent — recommend same stack, top position, for the coding model to have one clear container.
- Exact default detent fractions (0.12 / 0.5 / 0.98 above are placeholders — validate against target device sizes).
- Whether macOS window is resizable enough that `cornerPanelHeightRange` needs to react to window resize (likely yes — recompute max on window size change).
