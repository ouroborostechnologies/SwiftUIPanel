import SwiftUI
@testable import SwiftUIPanel
import Testing

@Suite("Panel heights")
struct PanelHeightsTests {

  private let style = PanelStyle()
  private var layout: PanelHeights {
    PanelHeights(availableHeight: 800, detents: Detent.defaultSet, barHeight: 64, style: style)
  }

  @Test("Detent heights are fractions of the container, floored at the bar slot")
  func heights() {
    // .minimized is fraction 0: exactly the bar, no main slot.
    #expect(layout.height(of: .minimized) == 64)
    #expect(layout.height(of: .half) == 400)
    #expect(layout.height(of: .full) == 800)
    #expect(layout.smallest == .minimized)
    #expect(layout.largest == .full)
    let shuffled = PanelHeights(availableHeight: 800, detents: [.full, .minimized, .half],
                                barHeight: 64, style: style)
    #expect(shuffled.detents == [.minimized, .half, .full])
  }

  @Test("A detent outside the set resolves to the smallest")
  func resolved() {
    #expect(layout.resolved(.half) == .half)
    #expect(layout.resolved(Detent(fraction: 0.31)) == .minimized)
  }

  @Test("An empty detent set falls back to half rather than crashing")
  func emptyDetents() {
    let layout = PanelHeights(availableHeight: 800, detents: [], barHeight: 0, style: style)
    #expect(layout.detents == [.half])
  }

  @Test("Dragging up grows the panel; down shrinks it")
  func dragDirection() {
    #expect(layout.height(from: .half, draggedBy: -100) == 500)
    #expect(layout.height(from: .half, draggedBy: 100) == 300)
  }

  @Test("Past the end detents the panel rubber-bands at the style's rate")
  func rubberBand() {
    let over = layout.height(from: .full, draggedBy: -100)
    #expect(abs(over - (800 + 100 * style.rubberBandFactor)) < 1e-9)
    let under = layout.height(from: .minimized, draggedBy: 100)
    #expect(abs(under - (64 - 100 * style.rubberBandFactor)) < 1e-9)
  }

  @Test("Snapping follows the projected stop, so a short fast flick changes detent")
  func velocitySnapping() {
    // Lifted after 30pt, but the projection says it would have travelled 250.
    #expect(layout.snappedDetent(from: .half, projecting: -250) == .full)
    #expect(layout.snappedDetent(from: .half, projecting: 250) == .minimized)
    // A slow drag that would stop near where it is stays put.
    #expect(layout.snappedDetent(from: .half, projecting: 40) == .half)
  }

  @Test("A flick past the last detent lands on it")
  func overshoot() {
    #expect(layout.snappedDetent(from: .half, projecting: -2000) == .full)
    #expect(layout.snappedDetent(from: .full, projecting: 5000) == .minimized)
  }

  @Test("Margins collapse only over the final approach to .full")
  func fullScreenProgress() {
    let band = style.marginDissolveDistance
    #expect(layout.dissolveProgress(atHeight: 400) == 0)
    #expect(layout.dissolveProgress(atHeight: 800 - band) == 0)
    #expect(abs(layout.dissolveProgress(atHeight: 800 - band / 2) - 0.5) < 1e-9)
    #expect(layout.dissolveProgress(atHeight: 800) == 1)
    // Rubber-banding past the top stays clamped.
    #expect(layout.dissolveProgress(atHeight: 820) == 1)
  }

  @Test("A detent set capped short of .full keeps its margins")
  func noCollapseWithoutFull() {
    let capped = PanelHeights(availableHeight: 800, detents: [.minimized, .half], barHeight: 64, style: style)
    #expect(capped.dissolveProgress(atHeight: 400) == 0)
    #expect(capped.dissolveProgress(atHeight: 800) == 0)
  }
}

@Suite("Panel widths")
struct PanelWidthsTests {

  private func layout(available: CGFloat = 900) -> PanelWidths {
    PanelWidths(configuredRange: 280 ... 520, available: available)
  }

  @Test("Width is capped by its own range and by the room beside the button stack")
  func caps() {
    #expect(layout().effectiveRange == 280 ... 520)
    #expect(layout().clamped(800) == 520)
    #expect(layout(available: 400).clamped(800) == 400)
    #expect(layout().clamped(100) == 280)
  }

  @Test("A container smaller than the minimum never inverts the range")
  func tinyContainer() {
    #expect(layout(available: 100).effectiveRange == 280 ... 280)
  }
}

@Suite("Chrome insets")
struct ChromeInsetsTests {

  private let container = CGSize(width: 400, height: 900)

  @Test("The margin from each edge, unless the safe area asks for more")
  func safeAreaWins() {
    // iPhone landscape: Dynamic Island at the sides, home indicator below.
    let landscape = EdgeInsets(margin: 16, clearing: EdgeInsets(top: 0, leading: 59, bottom: 21, trailing: 59))
    #expect(landscape == EdgeInsets(top: 16, leading: 59, bottom: 21, trailing: 59))
    // No safe area at all (a Mac window): the margin everywhere.
    let none = EdgeInsets(margin: 16, clearing: EdgeInsets())
    #expect(none == EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
  }

  @Test("On narrow, the panel covers the bottom, the toast the top, the stack a column")
  func narrow() {
    let insets = ChromeInsets.covering(
      panel: CGRect(x: 12, y: 600, width: 376, height: 288),
      toast: CGRect(x: 12, y: 16, width: 376, height: 52),
      buttonStack: CGRect(x: 340, y: 76, width: 48, height: 120),
      in: container, mode: .bottomSheet)
    #expect(insets.bottom == 300)
    #expect(insets.top == 68)
    #expect(insets.trailing == 60)
    #expect(insets.leading == 0)
  }

  @Test("On wide, the panel covers a leading column instead of the bottom")
  func wide() {
    let insets = ChromeInsets.covering(
      panel: CGRect(x: 16, y: 16, width: 340, height: 500),
      toast: CGRect(x: 420, y: 16, width: 560, height: 52),
      buttonStack: CGRect(x: 1336, y: 16, width: 48, height: 200),
      in: CGSize(width: 1400, height: 900), mode: .floatingCorner)
    #expect(insets.leading == 356)
    #expect(insets.top == 68)
    #expect(insets.trailing == 64)
    #expect(insets.bottom == 0)
  }

  @Test("A hidden surface contributes nothing")
  func hidden() {
    let insets = ChromeInsets.covering(panel: .zero, toast: .zero, buttonStack: .zero,
                                       in: container, mode: .bottomSheet)
    #expect(insets == EdgeInsets())
  }
}

@Suite("Toast span")
struct ToastSpanTests {

  /// A 1400pt Mac window: a 340pt panel one 16pt margin in, and a 36pt button
  /// stack one margin from the trailing edge.
  private func span(containerWidth: CGFloat = 1400, panelWidth: CGFloat? = 340,
                    preferredWidth: CGFloat = 560) -> ToastSpan {
    ToastSpan(containerWidth: containerWidth,
              stripLeading: panelWidth.map { 16 + $0 + 16 } ?? 16,
              stripTrailing: containerWidth - 16 - (36 + 16),
              preferredWidth: preferredWidth)
  }

  @Test("With room on both sides the toast is centred on the container")
  func centred() {
    let span = span()
    #expect(span.width == 560)
    #expect(span.originX == 420)
    // Centred means centred: equal room either side of it.
    #expect(span.originX == span.containerWidth - (span.originX + span.width))
  }

  @Test("A panel that reaches past the centre slides the toast clear of it")
  func clearsPanel() {
    // iPhone landscape: the strip is barely wider than the toast, so centring
    // would put it under the panel.
    let span = span(containerWidth: 874)
    #expect(span.stripLeading == 372)
    #expect(span.stripTrailing == 806)
    #expect(span.width == 434)
    #expect(span.originX == 372)
  }

  @Test("A strip narrower than the toast caps its width rather than overhanging")
  func cappedByStrip() {
    let span = span(containerWidth: 900, panelWidth: 520)
    #expect(span.width == 280)
    #expect(span.originX == 552)
    #expect(span.originX + span.width <= span.stripTrailing)
  }

  @Test("Hiding the panel frees the leading side and the toast recentres")
  func panelHidden() {
    let span = span(containerWidth: 874, panelWidth: nil)
    #expect(span.width == 560)
    #expect(span.originX == 157)
  }

  @Test("No room at all leaves no toast rather than a negative one")
  func noRoom() {
    let span = ToastSpan(containerWidth: 400, stripLeading: 380, stripTrailing: 340, preferredWidth: 560)
    #expect(span.width == 0)
    #expect(span.originX == 380)
  }
}

@Suite("Layout mode")
struct LayoutModeTests {

  @Test("The mode follows the container's width, at the style's breakpoint")
  func modeByWidth() {
    var style = PanelStyle()
    style.narrowestFloatingWidth = 700
    #expect(LayoutMode.resolve(width: 390, style: style) == .bottomSheet)
    #expect(LayoutMode.resolve(width: 699, style: style) == .bottomSheet)
    #expect(LayoutMode.resolve(width: 700, style: style) == .floatingCorner)
    #expect(LayoutMode.resolve(width: 2000, style: style) == .floatingCorner)
    // The breakpoint is a style value, so moving it moves the layout.
    var narrower = PanelStyle()
    narrower.narrowestFloatingWidth = 400
    #expect(LayoutMode.resolve(width: 500, style: narrower) == .floatingCorner)
  }

  @Test("An override on the controller wins over the width")
  func override() {
    let controller = PanelController()
    controller.layoutModeOverride = .bottomSheet
    #expect((controller.layoutModeOverride ?? .floatingCorner) == .bottomSheet)
  }
}

@Suite("Detents")
struct DetentTests {

  @Test("Fractions are clamped to the unit interval")
  func clamped() {
    #expect(Detent(fraction: 1.5).fraction == 1)
    #expect(Detent(fraction: -1).fraction == 0)
  }
}

@Suite("Controller")
struct PanelControllerTests {

  @Test("A fresh controller starts visible, half open, with no toast and no chrome reported")
  func defaults() {
    let controller = PanelController()
    #expect(controller.isPanelVisible)
    #expect(!controller.isToastVisible)
    #expect(controller.detent == .half)
    #expect(controller.detents == Detent.defaultSet)
    #expect(controller.contentInsets == EdgeInsets())
    #expect(controller.panelFrame == .zero)
  }

  @Test("The initial detent is simply the value the controller was given")
  func initialDetent() {
    let controller = PanelController()
    controller.detent = .full
    #expect(controller.detent == .full)
  }

  @Test("Reporting a pass writes every published value at once")
  func publish() {
    let controller = PanelController()
    let panel = CGRect(x: 16, y: 16, width: 340, height: 500)
    controller.report(ChromeGeometry(layoutMode: .floatingCorner,
                                     contentInsets: EdgeInsets(top: 0, leading: 356, bottom: 0, trailing: 0),
                                     panelFrame: panel, toastFrame: .zero, buttonStackFrame: .zero))
    #expect(controller.layoutMode == .floatingCorner)
    #expect(controller.contentInsets.leading == 356)
    #expect(controller.panelFrame == panel)
  }
}
