# SwiftUIPanel (FloatingPanelKit)

A cross-platform SwiftUI package: a floating panel + overlay-button system for apps built around
one full-bleed content view. One component tree, adaptive per idiom:

- **iPhone** — a card floating above the bottom edge, inset from the display on every side, with
  detents (`.minimized`, `.half`, `.full`) as fractions of the height *inside* the safe area and
  margins — so `.full` leaves the Dynamic Island and a sliver of content visible and the handle
  always reachable. Over the last stretch to `.full` the side and bottom margins dissolve and the
  sheet goes edge-to-edge. Its corners are concentric with the display's own curvature (the
  radius shrinks by the inset; edge-to-edge it matches the screen exactly). Dragged from its handle
  or the top edge of its content, snapping by projected velocity.
- **iPad / Mac** — an inspector floating top-left, always inset a margin from the container,
  resizable from its trailing edge, bottom edge, and the corner between them (the grips draw
  nothing; the pointer changing is the cue). Height snaps on release to the `detents` applied to
  its available height, by projected velocity; width resizes freely. Capped by
  `cornerPanelWidthRange` / `cornerPanelHeightRange` and by the window (it never reaches the button
  stack). Corners concentric with the display's (iPad) or window's (Mac) curvature where it allows,
  else the style's radius. Pointer cues: system frame-resize arrows on macOS 15, `NSCursor` on
  macOS 14; on iPadOS 17 the pointer snaps onto the grip, since iOS 17 has no public resize-arrow
  shape. It floats over the content and never pushes it.

A **temporary taskbar** shares the chrome: above the sheet on iPhone (forcing it to `.minimized`),
top centre on iPad and Mac, where it takes `taskbarWidth` capped by the room between the panel and
the button stack, and slides clear of either rather than overlapping. A column of circular **overlay buttons** sits top-right, led by the
panel's show/hide toggle. Tabs are the package's own icon-over-label bottom bar on every platform,
drawn inside the panel's material. The package is completely
content-agnostic; it draws chrome and reports intent through closures.

## Usage

```swift
MyContentView()                               // your full-bleed content, already ignoring the safe area
  .floatingPanel(
    tabs: [FloatingPanelTab(id: "items", title: "Items", systemImage: "list.bullet"), …],
    selection: $selectedTab,
    isPanelVisible: $isPanelVisible,
    taskbar: isDrawing ? TemporaryTaskbarContent(id: "drawing") { DrawingBar() } : nil
  ) { tab in
    TabBody(tab)
  }
```

Overlay buttons are declared in the configuration —
`OverlayButtonKind.custom(id:systemImage:isActive:action:)` (with `isActive` rendering the symbol
filled, for a mode that is currently on), or `.menu(id:systemImage:content:)` for a button that
opens a menu — the compact answer to more actions than a phone has room for.

What the panel covers is published to the content's subtree:

```swift
@Environment(\.floatingPanelInsets) private var panelInsets   // bottom on iPhone, leading on iPad/Mac; live mid-drag
```

and, for bridging into non-SwiftUI inset APIs, as a raw frame via
`.onPreferenceChange(FloatingPanelGeometryKey.self)`.

Theme everything at once with `FloatingPanelConfiguration.style` (`FloatingChromeStyle`: material,
corner radius, shadow, margins, animation). `configuration.layoutModeOverride` forces a layout;
otherwise the device idiom decides (an iPad in split view still gets the corner panel).

## Layout

```
Sources/SwiftUIPanel/
  Core/        FloatingChromeStyle, FloatingPanelDetent, PanelLayoutMode, FloatingPanelConfiguration (+ tabs, buttons, taskbar)
  Views/       FloatingPanelModifier (entry point), BottomSheetPanel, FloatingCornerPanel,
               FloatingPanelTabBar, OverlayButtonStack (+ PanelVisibilityToggle), TemporaryTaskbar, FloatingChromeSurface
  Modifiers/   FloatingPanelInsets (environment key + geometry preference)
  Support/     PlatformIdiom, PanelLayoutMath (sheet detents and snapping, corner clamping, insets — unit-tested)
Tests/SwiftUIPanelTests/
```

```sh
swift test
```
