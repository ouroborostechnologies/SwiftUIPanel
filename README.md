# SwiftUIPanel

A floating panel, a toast, and two free-space containers over full-bleed SwiftUI content, on iOS,
iPadOS, and macOS. Design: [docs/SPEC.md](docs/SPEC.md).

## Wide

```
┌────────────────────────────────────┐
│  ┌─────────┐   ┌─────────┐         │
│  │  main   │   │  toast  │         │
│  │         │   └─────────┘         │
│  ├─────────┤  ┌──────────────────┐ │
│  │   bar   │  │                  │ │
│  └─────────┘  │  panelTrailing   │ │
│  ┌─────────┐  │                  │ │
│  │ aligned │  │                  │ │
│  └─────────┘  └──────────────────┘ │
└────────────────────────────────────┘
```

## Narrow

```
┌──────────────────────┐
│  ┌────────────────┐  │
│  │     toast      │  │
│  └────────────────┘  │
│  ┌────────────────┐  │
│  │                │  │
│  │  panelAligned  │  │
│  │   (over it,    │  │
│  │ panelTrailing) │  │
│  └────────────────┘  │
│  ┌────────────────┐  │
│  │      main      │  │
│  ├────────────────┤  │
│  │      bar       │  │
│  └────────────────┘  │
└──────────────────────┘
```

## Detents

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

## Focus

```
  .half          focused
┌────────────┐  ┌────────────┐
│            │  │            │
│ ┌────────┐ │  │            │
│ │  main  │ │  │            │
│ ├────────┤ │  │ ┌────────┐ │
│ │  bar   │ │  │ │  main  │ │
│ └────────┘ │  │ └────────┘ │
└────────────┘  └────────────┘
```

## Usage

```swift
@State private var panel = PanelController()

MyContentView()
  .floatingPanel(panel) {
      SectionBody(section)
  } bar: {
      SectionPicker($section)
  } toast: {
      EditingControls()
  } panelAligned: {
      ScaleBar()
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
  } panelTrailing: {
      PanelButtonStack { PanelVisibilityToggle() }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
  }
```
