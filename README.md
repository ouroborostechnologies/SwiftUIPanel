# SwiftUIPanel (FloatingPanelKit)

A cross-platform SwiftUI package that recreates the floating panel + map-overlay-button system used
in Apple Maps. One component tree, adaptive per idiom:

- **iPhone** — a bottom sheet with detents (`.minimized`, `.half`, `.full`), dragged from its handle
  or the top edge of its content, snapping by projected velocity.
- **iPad / Mac** — an inspector anchored top-left, resizable from its trailing edge, bottom edge,
  and the corner between them, capped by `cornerPanelWidthRange` / `cornerPanelHeightRange` and by
  the window (it never reaches the button stack). Pointer cues: system frame-resize arrows on
  macOS 15, `NSCursor` on macOS 14; on iPadOS 17 the pointer snaps onto the grip, since iOS 17
  has no public resize-arrow shape. It floats over the content and never pushes it.

A **temporary taskbar** shares the chrome: above the sheet on iPhone (forcing it to `.minimized`),
top-right on iPad and Mac. A column of circular **map buttons** sits top-right, led by the panel's
show/hide toggle. The package is content-agnostic and knows nothing about MapKit; it draws chrome
and reports intent through closures.

## Usage

```swift
MyMapView()                                   // your full-bleed content, already ignoring the safe area
  .floatingPanel(
    tabs: [FloatingPanelTab(id: "features", title: "Features", systemImage: "list.bullet"), …],
    selection: $selectedTab,
    isPanelVisible: $isPanelVisible,
    actions: FloatingPanelActions(onUserLocationTapped: …, onMapStyleTapped: …),
    taskbar: isDrawing ? TemporaryTaskbarContent(id: "drawing") { DrawingBar() } : nil
  ) { tab in
    TabBody(tab)
  }
```

What the panel covers is published to the content's subtree:

```swift
@Environment(\.floatingPanelInsets) private var panelInsets   // bottom on iPhone, leading on iPad/Mac; live mid-drag
```

and, for bridging into non-SwiftUI inset APIs, as a raw frame via
`.onPreferenceChange(FloatingPanelGeometryKey.self)`.

Theme everything at once with `FloatingPanelConfiguration.style` (`FloatingChromeStyle`: material,
corner radius, shadow, margins, animation). `configuration.layoutModeOverride` forces a layout;
otherwise the device idiom decides (an iPad in split view still gets the corner panel).

Beyond the spec, `MapOverlayButtonKind.menu(id:systemImage:content:)` adds a button that opens a
menu — the compact answer to more actions than a phone has room for.

## Layout

```
Sources/SwiftUIPanel/
  Core/        FloatingChromeStyle, FloatingPanelDetent, PanelLayoutMode, FloatingPanelConfiguration (+ tabs, buttons, actions, taskbar)
  Views/       FloatingPanelModifier (entry point), BottomSheetPanel, FloatingCornerPanel,
               FloatingPanelTabBar, MapOverlayButtonStack (+ PanelVisibilityToggle), TemporaryTaskbar, FloatingChromeSurface
  Modifiers/   FloatingPanelInsets (environment key + geometry preference)
  Support/     PlatformIdiom, PanelLayoutMath (sheet detents and snapping, corner clamping, insets — unit-tested)
Tests/SwiftUIPanelTests/
```

```sh
swift test
```
