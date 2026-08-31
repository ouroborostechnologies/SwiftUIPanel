# SwiftUIPanel — Design & Implementation Spec

A cross-platform (iOS / iPadOS / macOS) SwiftUI package that overlays a floating
panel, a toast, and a stack of buttons on top of a full-bleed content view, and
publishes the region they leave unobstructed.

The package is **content-agnostic**. It draws chrome, resolves layout, and reports
geometry. It never inspects, wraps, or owns the content it floats over, and it never
inspects the content it is handed to put inside its own surfaces.

---

## 1. Principles

These three constrain every decision below; where a later section seems to offer a
choice, these settle it.

### 1.1 Content agnosticism

- The **layout engine** has no opinion about what its surfaces contain. No tab model,
  no button model, no domain enums. Every slot is a `@ViewBuilder`.
- Opinionated helpers are allowed, but only *above* the engine and never on its
  required path. The tab layer (§9) is the one such helper: it is built out of the
  public primitive, adds nothing to the engine, and can be deleted without the panel
  noticing. Convenience is layered on agnosticism, never mixed into it.
- No dependency beyond SwiftUI. The package imports no domain framework, and no type
  or parameter in its API is named after one. A reader of the public API should not
  be able to tell what kind of app it was built for.
- The package reports *intent* (a surface was toggled, a size changed) and *geometry*
  (what is covered). Meaning belongs to the consumer.

### 1.2 No magic numbers, no screen measurements in layout code

Layout code contains no literal point values and no device or screen constants.

- Every point value the design needs is a **named, documented, consumer-overridable
  property on `PanelStyle`**. `PanelStyle` is the one file where a number is written
  down. Layout code reads names, never literals.
- Everything else is **measured or derived**: chrome heights come from
  `onGeometryChange`, available space from the container's own size, safe areas from
  the environment. Nothing is estimated from a known device.
- Proportions that are part of a definition are not magic numbers. `.half` is
  "half the available height" because half is what the detent *means*, not because
  0.5 measured well on a particular phone. A consumer's own `Detent(fraction:)` is
  their number, not one of ours.
- No `UIDevice`, no screen-size checks, no hardcoded breakpoint literals inline. The
  breakpoint that separates the two layouts is itself a named style value.

### 1.3 Abstractions need strong justification

A type earns its place by removing more complexity than it adds. Where this spec
introduces one — `PanelController`, `Detent`, `LayoutMode` — it states what it
replaces. Where the obvious abstraction is *absent* from the engine — no button type,
no toast content type — that absence is deliberate and §1.1 is why.

`PanelTab` is the deliberate exception, and it proves the rule: it exists because
most consumers want tabs, and it is confined to the optional layer precisely so the
engine can stay ignorant of it.

---

## 2. Terminology

| Term | Meaning |
|---|---|
| **content** | The consumer's full-bleed view. The package is a modifier on it. |
| **panel** | The main floating surface. Bottom-anchored on narrow, top-leading on wide. |
| **bar slot** | The panel's bottom slot. Always visible, at every detent. |
| **main slot** | The panel's upper slot. Renders nothing when closed. |
| **toast** | A transient surface, top-centre, sharing the panel's chrome. |
| **button stack** | A vertical column of consumer views, top-trailing. |
| **chrome** | The three surfaces together: panel, toast, button stack. |
| **available height** | Container height less safe areas and edge margins — the room a surface may occupy. |

"Bar slot" and "button stack" are kept distinct on purpose: one is inside the panel,
one is a separate surface.

---

## 3. The Panel

### 3.1 Anchoring

- **Narrow layout** — anchored to the bottom, horizontally centred, inset one edge
  margin from the container on each side (grown only where the safe area asks for
  more).
- **Wide layout** — anchored top-leading, inset one edge margin from the top and
  leading container edges.

It floats *over* the content. It never resizes or pushes the content; the content
learns what is covered through §6 and decides for itself.

### 3.2 Two slots

The panel has exactly two content slots:

- The **bar slot**, pinned to the panel's bottom edge, sized to its own content.
- The **main slot**, filling the remaining height above it.

A tab view is the expected combination — a row of tabs in the bar, the selected body
in the main slot — and §9 ships one ready-made. The panel itself models none of it:
it does not know what either slot contains, and it holds no selection state.

### 3.3 Detents

The panel resizes vertically between resting heights. The bar slot is visible at
every one of them.

A detent is a fraction of the **available height** — the container less safe areas
and edge margins — so the set is resolution-independent and the same three values
mean the same thing on a phone and on a Mac.

```swift
public struct Detent: Equatable, Hashable, Sendable {

    /// Only the bar slot. The main slot renders no content.
    public static let minimized = Detent(fraction: 0)
    /// Half open.
    public static let half = Detent(fraction: 0.5)
    /// Everything the safe area and margins allow.
    public static let full = Detent(fraction: 1)

    /// The three levels above, the default set.
    public static let defaultSet: [Detent] = [.minimized, .half, .full]

    /// Clamped to 0...1 on construction.
    public let fraction: CGFloat
    public init(fraction: CGFloat)
}
```

The set in use is `controller.detents`, defaulting to `.defaultSet`. Consumers may
supply their own — two detents, or four — and the drag, the snapping, and the wide
panel's vertical resize all read the same array. Nothing in the layout engine
assumes three.

- **`.minimized` never resolves below the bar slot.** A fraction of 0 floors at the
  **measured** height of the bar slot plus the panel's own insets — never a constant.
  Until the first measurement lands the panel lays out from the style's stated
  placeholder and corrects before anything is on screen (§1.2).
- **`.full` is all of the available height**, which already excludes safe areas and
  margins — so it leaves the top inset clear rather than covering the display.
- The initial detent is simply the value `detent` holds when the controller is
  created; there is no separate `initialDetent`. A value outside `detents` resolves
  to the smallest.

An open set rather than a closed enum: the arithmetic is identical either way — a
fraction of the available height — so the array costs nothing the enum would have
saved, and it keeps the number of resting heights the consumer's decision (§1.3).

### 3.4 Resizing

- Dragged from the panel's free edge — the top edge on narrow, the bottom edge on
  wide.
- The drag follows the finger or pointer continuously, and past the end detents it
  follows at a reduced rate (the rate is a style value).
- On release, the panel snaps to the detent nearest the **projected** stopping point,
  not the release point, so a fast flick commits to the next detent even when the
  distance was short.
- Detent arithmetic is pure functions over the available height, kept out of the
  views and unit-tested. Snapping is the part that decides whether the panel feels
  right; it is tested rather than eyeballed.

### 3.5 Visibility

`isPanelVisible` on the controller. Toggling it slides the panel off the container
edge it is anchored to — downwards on narrow, leading on wide — and back. A slide,
with no fade: the panel is not disappearing, it is leaving.

---

## 4. The Toast

- Anchored **top-centre**, on every layout. It belongs to the container, not to the
  panel.
- Shares the panel's chrome exactly: same material, same corner radius, same shadow.
  It reads as a sibling surface, not a second visual language.
- Height is whatever its content needs, floored at the style's minimum touch height.
- **Narrow layout** — the panel's width, so the two surfaces align on both edges.
- **Wide layout** — the style's preferred toast width, capped by the strip left free
  between the panel's trailing edge and the button stack's leading edge. Centred on
  the container, then *slid* clear of either neighbour rather than squeezed. Only a
  strip narrower than the toast wants costs it width.
- Presence is the consumer's call (`isToastVisible`); the package decides only how
  and where. It has no timer and does not auto-dismiss.
- The toast never moves, resizes, or collapses the panel. The two surfaces are
  independent on every layout.

---

## 5. The Button Stack

- A vertical column of consumer-supplied views, anchored top-trailing, inset one edge
  margin.
- The stack lays out and spaces its children and applies the shared button chrome to
  its subtree as the default button style — so a plain `Button` gets the circular
  material treatment for free, and a consumer who wants something else overrides the
  style. The stack never inspects what it was given.

```swift
/// The circular material treatment shared by every button in the stack.
/// Public so a consumer can apply it elsewhere, or opt out inside the stack.
public struct PanelButtonStyle: ButtonStyle { … }
```

- Button diameter scales with the user's type size rather than staying pinned to
  points.

### 5.1 The visibility toggle

The package ships one ready-made control:

```swift
/// Toggles `isPanelVisible` on the controller in the environment.
/// Standalone and optional — place it wherever it belongs, typically first
/// in the button stack.
public struct PanelVisibilityToggle: View { public init() }
```

It is a view the consumer places, not behaviour the stack imposes. A consumer who
wants no toggle simply omits it; one who wants it somewhere else puts it there. Its
glyph reflects where the panel actually is on the resolved layout.

---

## 6. The Safe Area

With three surfaces floating over the content, the consumer needs to know what
region is left unobstructed — to centre something in the clear space, to inset
attribution or controls, to keep a selection visible.

The controller publishes:

```swift
/// What the chrome covers, per edge. The union of every visible surface.
public internal(set) var contentInsets: EdgeInsets

/// Each surface's frame in the content's coordinate space, for consumers
/// bridging into non-SwiftUI inset APIs.
public internal(set) var panelFrame: CGRect
public internal(set) var toastFrame: CGRect
public internal(set) var buttonStackFrame: CGRect
```

- `contentInsets` accounts for **all three** surfaces, not the panel alone. On narrow
  that is typically a bottom inset from the panel and a top inset from the toast; on
  wide, a leading inset from the panel, a trailing inset from the button stack, and a
  top inset from the toast. Unused edges are zero.
- Every value updates continuously during an interactive drag or resize, so content
  tracks the visible edge rather than jumping on release. This is the intended
  behaviour, not an edge case.
- A hidden surface contributes nothing.

```swift
Text("Centred in the clear space")
    .padding(panel.contentInsets)
```

The frames are the escape hatch, for feeding a non-SwiftUI inset API that wants a
rect. Consumers should reach for `contentInsets` first.

---

## 7. `PanelController` — the single source of truth

One observable object owns every piece of state the consumer sets and every piece
the layout engine reports.

```swift
@Observable
public final class PanelController {

    // Consumer-owned state
    public var isPanelVisible: Bool = true
    public var isToastVisible: Bool = false
    /// The panel's resting height. Its value at init is the initial detent.
    public var detent: Detent = .half
    /// The resting heights the panel snaps between.
    public var detents: [Detent] = Detent.defaultSet

    // Consumer-owned configuration
    public var style: PanelStyle = .default
    /// Forces a layout; `nil` resolves from the container's width.
    public var layoutModeOverride: LayoutMode? = nil

    // Published by the layout engine
    public internal(set) var layoutMode: LayoutMode
    public internal(set) var contentInsets: EdgeInsets
    public internal(set) var panelFrame: CGRect
    public internal(set) var toastFrame: CGRect
    public internal(set) var buttonStackFrame: CGRect

    public init() {}
}
```

**Why this abstraction earns its place (§1.3):** it replaces a binding per surface,
a configuration struct threaded through the initialiser, and a pair of environment
and preference keys, with one reference the consumer holds and the engine writes.
State that must agree — the panel's drawn height and the inset published for it —
becomes one value written once per layout pass, so the chrome and the content
underneath cannot disagree. It also gives the consumer a handle to *drive* the
chrome (open the panel, show the toast) from anywhere in their view tree, which
bindings scattered across a modifier's parameters do not.

`style` living here is deliberate: global padding, margins, materials, and the
layout breakpoint are all read from one place a consumer can reach at runtime.

The controller is placed in the content's environment by the modifier, so nested
views — `PanelVisibilityToggle` included — reach it without being passed it.

---

## 8. Public API

### 8.1 The entry point

The package is a **modifier**, not a container. It attaches to whatever full-bleed
content already exists; it never re-parents it. Adoption is "add one modifier,"
not "restructure your hierarchy around ours."

```swift
public extension View {
    func floatingPanel<Main: View, Bar: View, Toast: View, Buttons: View>(
        _ controller: PanelController,
        @ViewBuilder main: @escaping () -> Main,
        @ViewBuilder bar: @escaping () -> Bar,
        @ViewBuilder toast: @escaping () -> Toast = { EmptyView() },
        @ViewBuilder buttons: @escaping () -> Buttons = { EmptyView() }
    ) -> some View
}
```

```swift
@State private var panel = PanelController()
@State private var selection = Section.items

MyContent()                       // already ignoring the safe area
    .floatingPanel(panel) {
        SectionBody(selection)    // main slot
    } bar: {
        SectionPicker($selection) // bar slot — visible at every detent
    } toast: {
        EditingControls()
    } buttons: {
        PanelVisibilityToggle()
        Button { locate() } label: { Image(systemName: "location") }
    }
```

Attach it to the content itself — the view that already ignores the safe area. The
chrome keeps itself inside the safe area.

### 8.2 Layout mode

```swift
public enum LayoutMode: Sendable, Hashable {
    /// Narrow: the panel is a bottom-anchored sheet.
    case bottomSheet
    /// Wide: the panel floats top-leading.
    case floatingCorner

    /// The mode a container of `width` points gets. Public so a consumer can
    /// make the same call — what to show where — from the same rule.
    public static func resolve(width: CGFloat, style: PanelStyle) -> LayoutMode
}
```

Resolved from the **container's width**, not the device idiom: one view hierarchy
serves a phone, a narrow iPad split view, and a wide Mac window, and changes only
its presentation as the window resizes. The threshold is
`PanelStyle.narrowestFloatingWidth`. `layoutModeOverride` forces a mode.

The consumer writes no `#if os(...)`. All platform-conditional code lives in the two
internal panel implementations.

### 8.3 Style tokens

One struct, every number the package uses, all consumer-overridable. This is the
whole of §1.2's "one file where a number is written down."

```swift
public struct PanelStyle: Sendable {

    // Surfaces
    public var material: Material              // panel and toast
    public var buttonMaterial: Material        // lighter; content reads through
    public var cornerRadius: CGFloat           // continuous
    public var shadowRadius: CGFloat
    public var shadowOpacity: Double
    public var shadowYOffset: CGFloat

    // Spacing
    public var edgeMarginCompact: CGFloat      // narrow layouts
    public var edgeMarginRegular: CGFloat      // wide layouts
    public var surfaceSpacing: CGFloat         // between chrome surfaces
    public var buttonSpacing: CGFloat          // within the button stack

    // Sizing
    public var buttonDiameter: CGFloat         // scaled by type size
    public var minimumTouchHeight: CGFloat     // toast and bar-slot floor
    public var panelWidth: CGFloat             // wide layouts
    public var toastWidth: CGFloat             // wide layouts; capped by the free strip
    public var narrowestFloatingWidth: CGFloat // the layout breakpoint

    // Interaction
    public var rubberBandFactor: CGFloat       // travel past the end detents
    public var animation: Animation            // every detent and visibility change

    public static let `default` = PanelStyle()
}
```

Corner radii are **concentric with the container** where the platform exposes its
curvature — inset by a margin, the radius shrinks by that margin — falling back to
`cornerRadius`. Edge margins grow, never shrink, to clear a safe area that asks for
more; nothing is device-checked, because the safe area already encodes the hardware.

---

## 9. The tab layer (optional)

Most consumers will put a row of tabs in the bar slot and the selected body in the
main slot. The package ships that, so the common case is not homework — but it ships
it as a **layer above the primitive**, never as a requirement.

Everything here is built out of §8.1 and adds no capability to the layout engine.
Delete this layer and the panel is unchanged; the engine does not know it exists.
That is what keeps §1.1 true while still making the ordinary case one call.

### 9.1 The pieces

```swift
public struct PanelTab<ID: Hashable>: Identifiable {
    public let id: ID
    public let title: String
    public let systemImage: String
    public init(id: ID, title: String, systemImage: String)
}

/// Icon-over-label tabs, styled for the panel's bar slot. Usable on its own
/// in `bar:`, for consumers who want the standard bar but a custom `main:`.
public struct PanelTabBar<ID: Hashable>: View {
    public init(_ tabs: [PanelTab<ID>], selection: Binding<ID>)
}
```

`PanelTab` is a concrete title-and-symbol model, and that is fine *here* — this layer
is opinionated by design. A consumer who needs something else writes their own view
into `bar:` and loses nothing.

### 9.2 The convenience entry point

```swift
public extension View {
    func floatingPanel<ID: Hashable, Main: View, Toast: View, Buttons: View>(
        _ controller: PanelController,
        tabs: [PanelTab<ID>],
        selection: Binding<ID>,
        @ViewBuilder main: @escaping (ID) -> Main,
        @ViewBuilder toast: @escaping () -> Toast = { EmptyView() },
        @ViewBuilder buttons: @escaping () -> Buttons = { EmptyView() }
    ) -> some View
}
```

Its whole implementation is the primitive with the bar slot filled in:

```swift
floatingPanel(controller) { main(selection.wrappedValue) }
    bar: { PanelTabBar(tabs, selection: selection) }
    toast: toast
    buttons: buttons
```

```swift
MyContent()
    .floatingPanel(panel, tabs: tabs, selection: $section) { section in
        SectionBody(section)
    } buttons: {
        PanelVisibilityToggle()
    }
```

### 9.3 One behaviour it adds

`PanelTabBar` reads the controller from the environment, so a tap on any tab — the
already-selected one included — opens a minimized panel to the next detent up. A
bare tab bar switching invisible content helps no one.

This nicety lives here rather than in the engine on purpose: the primitive stays
ignorant of what its bar contains, and the layer that *does* know adds the
behaviour. A consumer building their own bar can do the same by writing to
`controller.detent`.

---

## 10. Package structure

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

  PanelLayoutMath.swift        // detent + inset arithmetic, pure and unit-tested
  ContainerCornerRadius.swift
  ResizeCursor.swift

  Tabs/                        // §9 — optional layer, built on the public API
    PanelTab.swift
    PanelTabBar.swift
    FloatingPanelModifier+Tabs.swift

Tests/SwiftUIPanelTests/
```

`BottomSheetPanel` and `FloatingCornerPanel` are internal; the modifier picks between
them and presents one API outward.

`Tabs/` is a separate directory to keep the boundary honest: nothing outside it may
be imported by the engine, and nothing inside it may reach past the public API. If a
file in `Tabs/` ever needs internal access, the layering has been broken.

---

## 11. Implementation notes

- **One `GeometryReader`**, at the modifier level. Resolve the container size once
  and pass it down; nested readers thrash.
- **One pass per state change** yields the panel height, every surface frame, and the
  insets together. The chrome and the content's insets are computed from the same
  values, never independently.
- **Publish to the controller outside the layout pass** — from `onGeometryChange` or
  an equivalent, never inline in `body`. Writing observable state during view update
  is a runtime warning and a source of layout loops.
- **Place surfaces explicitly.** One full-container stack that ignores the safe area
  exactly once, with every surface positioned by alignment plus explicit safe-area
  padding — so placement never depends on how SwiftUI resolves safe areas for
  overlays, which is how a sheet ends up under the Dynamic Island.
- **Measure the bar slot** to resolve the floor under `.minimized`. Do not estimate it.
- **Snap by projected velocity**, from the drag's predicted end translation.
- **macOS pointer cues** on the resize edge, guarded and confined to the wide panel
  implementation.
- Every drag and visibility change animates with `style.animation`, and nothing else.

---

## 12. Resolved questions

The three questions §13 used to leave open, and the answers now in the code.

### 12.1 The wide panel resizes freely by width

Kept. The trailing and corner grips stay, and `PanelStyle.panelWidthRange` bounds
them; the upper bound is capped again by the room left beside the button stack.

Height went the other way: it is a **detent on both layouts**, so `controller.detent`
is *the* panel's resting height whatever the layout, `.minimized` floors at the
measured bar slot on wide exactly as it does on narrow, and the bottom grip snaps by
projected velocity like the sheet's drag. That removed a second height model —
`initialCornerPanelHeight`, `cornerPanelHeightRange`, and `cornerPanelSnapsVertically`
are all gone — and it is why §8.3's token list carries `panelWidthRange` but no
height equivalent.

### 12.2 The full-screen margin dissolve stays

Kept, with `PanelStyle.marginDissolveDistance` as its one token. Over the last stretch
to `.full` the sheet's side and bottom margins collapse and it goes edge-to-edge, its
corners turning concentric with the display's own curvature as they do.

### 12.3 The toast keeps its margins at `.full`

The toast is an inset card at the top whatever the panel is doing. §4's last line —
the two surfaces are independent on every layout — settles it: the toast is nowhere
near the panel's edge, and coupling its width to the panel's drag would be the one
piece of coordination this revision set out to remove.

---

## 13. Notes on the implementation

- **The button stack steps below the toast where the two would collide.** §4 puts the
  toast top-centre at the panel's width on narrow; §5 puts the stack top-trailing on
  every layout. On a narrow container those are the same points. The stack therefore
  takes `toastFrame.maxY + surfaceSpacing` as its top whenever the toast reaches its
  column — always on narrow, never on wide, where the toast's strip already keeps
  clear of it. One rule, no layout branch.
- **`PanelButtonStyle(prominent:)`.** §5 shows the style with its members elided. It
  takes one: `prominent` fills the circle with the accent colour, for the single
  primary action of a screen. Without it a consumer wanting an accented button has to
  re-implement the whole circular treatment to change its fill.
- **`ContainerCornerRadius` holds the only literals outside `PanelStyle`**: the
  macOS window radius per major release, since AppKit exposes no API for it. They are
  measurements of the system's own window shape rather than design values — the
  reason §1.2's "everything else is measured or derived" does not reach them — and
  the UIKit side reads the display's radius rather than hardcoding it.
