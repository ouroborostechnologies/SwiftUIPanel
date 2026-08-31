# SwiftUIPanel

A cross-platform SwiftUI package (iOS / iPadOS / macOS) that overlays a floating panel, a toast,
and a stack of buttons on top of a full-bleed content view, and publishes the region they leave
unobstructed.

The package is **content-agnostic**: it draws chrome, resolves layout, and reports geometry. Every
slot is a `@ViewBuilder`, and no type in its API is named after a domain. See
[docs/SPEC.md](docs/SPEC.md) for the design it implements.

## Layouts

One view hierarchy, two presentations, resolved from the **container's width** — so a phone, a
narrow iPad split view, and a wide Mac window share one tree and change only how the panel is
presented as the window resizes. `PanelStyle.narrowestFloatingWidth` is the threshold;
`PanelController.layoutModeOverride` forces a mode.

**Wide** — the panel floats top-leading, the toast sits top-centre, the buttons run down the
trailing edge.

```
┌────────────────────────────────────┐
│  ┌─────────┐   ┌─────────┐      ○  │
│  │  main   │   │  toast  │      ○  │
│  │         │   └─────────┘      ○  │
│  ├─────────┤                       │
│  │   bar   │                       │
│  └─────────┘                       │
│                                    │
└────────────────────────────────────┘
```

The panel is resized from its trailing edge, its bottom edge, or the corner between them (the
grips draw nothing; the pointer changing is the cue). Width moves freely inside
`panelWidthRange` and never reaches the buttons; height is a detent. The toast takes
`toastWidth`, capped by the strip left free between the two — centred on the container, then slid
clear rather than squeezed.

**Narrow** — the panel becomes a bottom sheet. The toast keeps the top, at the panel's width so
the two align on either edge, and the button stack steps below it.

```
┌──────────────────────┐
│  ┌────────────────┐  │
│  │     toast      │  │
│  └────────────────┘  │
│                   ○  │
│                   ○  │
│                   ○  │
│                      │
│  ┌────────────────┐  │
│  │      main      │  │
│  ├────────────────┤  │
│  │      bar       │  │
│  └────────────────┘  │
└──────────────────────┘
```

The sheet is dragged from its handle or the top of its content, snapping by projected velocity so
a fast flick commits to the next detent even when the distance was short.

### Slots and detents

The panel has two slots: `bar` is pinned to its bottom edge and shows at every detent, `main`
fills what is left. A detent is a fraction of the height available *inside* the safe area and
margins, so `.full` still leaves the top inset clear. Over its last stretch to `.full` a sheet's
side and bottom margins dissolve and it goes edge-to-edge, its corners staying concentric with the
display's own curvature.

```
  .minimized        .half           .full
┌────────────┐  ┌────────────┐  ┌────────────┐
│            │  │            │  ├────────────┤
│            │  │ ┌────────┐ │  │            │
│            │  │ │  main  │ │  │    main    │
│ ┌────────┐ │  │ ├────────┤ │  │            │
│ │  bar   │ │  │ │  bar   │ │  ├────────────┤
│ └────────┘ │  │ └────────┘ │  │    bar     │
└────────────┘  └────────────┘  └────────────┘
```

`.minimized` never resolves shorter than the bar slot's measured height. Supply your own
`PanelController.detents` — two, or four — and the drag, the snapping, and the wide panel's
vertical resize all read them.

### The toast and the buttons

The toast shares the panel's chrome and belongs to the container, not to the panel: it never
moves, resizes, or collapses it, and the package never dismisses it — `isToastVisible` is yours.

The button stack takes consumer views and applies the shared circular chrome to its subtree as the
default button style, so a plain `Button` arrives dressed.

The chrome floats over the content and never pushes it. What it covers is reported through the
controller.

## Usage

```swift
@State private var panel = PanelController()
@State private var section = Section.items

MyContentView()                       // already ignoring the safe area
  .floatingPanel(panel) {
      SectionBody(section)            // main slot
  } bar: {
      SectionPicker($section)         // bar slot — visible at every detent
  } toast: {
      EditingControls()
  } buttons: {
      PanelVisibilityToggle()
      Button { locate() } label: { Image(systemName: "location") }
  }
```

Most consumers want tabs in the bar slot, so the package ships that as a layer above the
primitive — built out of the public API, and deletable without the engine noticing:

```swift
MyContentView()
  .floatingPanel(panel, tabs: tabs, selection: $section) { section in
      SectionBody(section)
  } buttons: {
      PanelVisibilityToggle()
  }
```

## The controller

`PanelController` is the single source of truth: everything the consumer sets, and everything the
layout engine reports. It is `@Observable`, and the modifier puts it in the content's environment
so nested views reach it without being passed it.

```swift
panel.isPanelVisible          // slides the panel off its anchored edge and back
panel.isToastVisible          // presence is yours; placement is the package's
panel.detent                  // the panel's resting height; its value at init is the initial one
panel.detents                 // the heights it snaps between — two, three, or four
panel.style                   // every number and material, in one place, at runtime
panel.layoutModeOverride      // forces a layout; nil resolves from the width

panel.layoutMode              // published: what the width resolved to
panel.contentInsets           // published: what all three surfaces cover, live mid-drag
panel.panelFrame              // published: raw frames, for non-SwiftUI inset APIs
panel.toastFrame
panel.buttonStackFrame
```

```swift
Text("Centred in the clear space")
    .padding(panel.contentInsets)
```

`PanelStyle` is the one file in which a point value is written down — materials, radii, margins,
spacings, the button diameter, the layout breakpoint, the rubber-band rate, the animation.
Everything else the layout needs it measures.

## Package structure

```
Sources/SwiftUIPanel/
  PanelController.swift        // the shared source of truth
  PanelStyle.swift             // every number, named
  Detent.swift
  LayoutMode.swift

  FloatingPanelModifier.swift  // public entry point; one GeometryReader, one pass
  BottomSheetPanel.swift       // narrow layout + drag
  FloatingCornerPanel.swift    // wide layout + resize
  Toast.swift
  ButtonStack.swift            // + PanelButtonStyle, PanelVisibilityToggle
  PanelSurface.swift           // shared material/radius/shadow treatment

  PanelLayoutMath.swift        // detent, toast, and inset arithmetic — pure and unit-tested
  ContainerCornerRadius.swift
  ResizeCursor.swift

  Tabs/                        // the optional layer, built on the public API
    PanelTab.swift
    PanelTabBar.swift
    FloatingPanelModifier+Tabs.swift

Tests/SwiftUIPanelTests/
```

```sh
swift test
```
