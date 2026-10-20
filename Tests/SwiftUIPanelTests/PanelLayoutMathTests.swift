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

  @Test("The screen recedes with the dissolve, or from an earlier start")
  func recede() {
    // By default the scrim and the fade ride the margin dissolve.
    for height in [400.0, 760, 800] {
      #expect(layout.recedeProgress(atHeight: height) == layout.dissolveProgress(atHeight: height))
    }
    var early = PanelStyle()
    early.recedeStartFraction = 0.75
    let sooner = PanelHeights(availableHeight: 800, detents: Detent.defaultSet, barHeight: 64, style: early)
    #expect(sooner.recedeProgress(atHeight: 600) == 0)
    #expect(abs(sooner.recedeProgress(atHeight: 700) - 0.5) < 1e-9)
    #expect(sooner.recedeProgress(atHeight: 800) == 1)
    // Never behind the dissolve, and nothing without a .full to reach.
    #expect(sooner.recedeProgress(atHeight: 790) >= sooner.dissolveProgress(atHeight: 790))
    let capped = PanelHeights(availableHeight: 800, detents: [.minimized, .half], barHeight: 64, style: early)
    #expect(capped.recedeProgress(atHeight: 400) == 0)
  }

  @Test("A detent set capped short of .full keeps its margins")
  func noCollapseWithoutFull() {
    let capped = PanelHeights(availableHeight: 800, detents: [.minimized, .half], barHeight: 64, style: style)
    #expect(capped.dissolveProgress(atHeight: 400) == 0)
    #expect(capped.dissolveProgress(atHeight: 800) == 0)
  }

  @Test("A focused panel takes its content's height, between no detents")
  func fitted() {
    // Neither a detent height nor the bar floor: the bar slot is not shown.
    #expect(layout.fittedHeight(180, resting: .half) == 180)
    #expect(layout.fittedHeight(40, resting: .half) == 40)
  }

  @Test("A focused panel never outgrows the available height")
  func fittedCap() {
    #expect(layout.fittedHeight(1200, resting: .half) == 800)
    #expect(layout.fittedHeight(-10, resting: .half) == 0)
  }

  @Test("Until its content is measured, a focused panel rests at its detent")
  func fittedBeforeMeasurement() {
    #expect(layout.fittedHeight(nil, resting: .half) == 400)
    #expect(layout.fittedHeight(nil, resting: .minimized) == 64)
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

  @Test("On narrow, the panel covers the bottom and nothing else")
  func narrow() {
    let insets = ChromeInsets.covering(
      panel: CGRect(x: 12, y: 600, width: 376, height: 288),
      in: container, mode: .bottomSheet)
    #expect(insets.bottom == 300)
    #expect(insets.top == 0)
    #expect(insets.trailing == 0)
    #expect(insets.leading == 0)
  }

  @Test("On wide, the panel covers a leading column instead of the bottom")
  func wide() {
    let insets = ChromeInsets.covering(
      panel: CGRect(x: 16, y: 16, width: 340, height: 500),
      in: CGSize(width: 1400, height: 900), mode: .floatingCorner)
    #expect(insets.leading == 356)
    #expect(insets.top == 0)
    #expect(insets.trailing == 0)
    #expect(insets.bottom == 0)
  }

  @Test("A hidden panel contributes nothing")
  func hidden() {
    let insets = ChromeInsets.covering(panel: .zero, in: container, mode: .bottomSheet)
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
    let trailing = CGRect(x: 364, y: 16, width: 1020, height: 868)
    controller.report(ChromeGeometry(layoutMode: .floatingCorner,
                                     contentInsets: EdgeInsets(top: 0, leading: 356, bottom: 0, trailing: 0),
                                     panelFrame: panel, toastFrame: .zero,
                                     panelAlignedFrame: .zero, panelTrailingFrame: trailing,
                                     freeSpaceOpacity: 0.25))
    #expect(controller.layoutMode == .floatingCorner)
    #expect(controller.contentInsets.leading == 356)
    #expect(controller.panelFrame == panel)
    #expect(controller.panelTrailingFrame == trailing)
    #expect(controller.freeSpaceOpacity == 0.25)
  }
}

@Suite("Panel regions")
struct PanelRegionsTests {

  /// An iPhone: a 393×852 container, an 8pt margin, safe areas top and bottom,
  /// and a sheet resting half open.
  private func narrow(panel: CGRect = CGRect(x: 8, y: 480, width: 377, height: 344),
                      contentTop: CGFloat = 59) -> PanelRegions {
    PanelRegions(mode: .bottomSheet,
                 container: CGSize(width: 393, height: 852),
                 edge: EdgeInsets(top: 59, leading: 8, bottom: 34, trailing: 8),
                 panelFrame: panel, panelWidth: 377,
                 contentTop: contentTop, spacing: 8, fadeDistance: 96)
  }

  /// A 1400×900 window: a 340pt panel one 16pt margin in from the top-leading
  /// corner, 500pt tall.
  private func wide(panel: CGRect = CGRect(x: 16, y: 16, width: 340, height: 500)) -> PanelRegions {
    PanelRegions(mode: .floatingCorner,
                 container: CGSize(width: 1400, height: 900),
                 edge: EdgeInsets(margin: 16, clearing: EdgeInsets()),
                 panelFrame: panel, panelWidth: 340,
                 contentTop: 16, spacing: 8, fadeDistance: 96)
  }

  @Test("On narrow the aligned area is the full width above the sheet")
  func narrowAligned() {
    let aligned = narrow().aligned
    #expect(aligned.minX == 8)
    #expect(aligned.width == 377)
    #expect(aligned.minY == 59)
    // Its bottom edge sits one spacing above the sheet's top.
    #expect(aligned.maxY == 472)
  }

  @Test("On wide the aligned area is the panel's own column, under the panel")
  func wideAligned() {
    let aligned = wide().aligned
    #expect(aligned.minX == 16)
    #expect(aligned.width == 340)
    #expect(aligned.minY == 524)
    #expect(aligned.maxY == 884)
  }

  @Test("A panel that fills its column leaves no aligned area, and no negative one")
  func alignedCollapses() {
    // A sheet dragged past its top inset: the area would be inverted.
    let aligned = narrow(panel: CGRect(x: 0, y: 40, width: 393, height: 812)).aligned
    #expect(aligned.height == 0)
    #expect(aligned.width == 377)
  }

  @Test("The aligned area fades over the last band of its own height")
  func alignedFade() {
    #expect(narrow().alignedOpacity == 1)
    // 48pt of room left, half the 96pt fade band.
    #expect(narrow(panel: CGRect(x: 8, y: 115, width: 377, height: 709)).alignedOpacity == 0.5)
    #expect(narrow(panel: CGRect(x: 0, y: 40, width: 393, height: 812)).alignedOpacity == 0)
  }

  @Test("On wide the trailing area is the strip beside the panel")
  func wideTrailing() {
    let trailing = wide().trailing
    #expect(trailing.minX == 364)
    #expect(trailing.maxX == 1384)
    #expect(trailing.minY == 16)
    #expect(trailing.maxY == 884)
  }

  @Test("On narrow the sheet leaves no strip, so the trailing area is the whole inset container")
  func narrowTrailing() {
    let trailing = narrow().trailing
    #expect(trailing.minX == 8)
    #expect(trailing.width == 377)
    #expect(trailing.minY == 59)
    #expect(trailing.maxY == 818)
    // It floats over the sheet rather than stopping at it, so controls stay
    // reachable at every detent.
    #expect(trailing.maxY > narrow().panelFrame.minY)
  }

  @Test("A visible toast pushes both areas below it")
  func clearsToast() {
    let regions = narrow(contentTop: 120)
    #expect(regions.aligned.minY == 120)
    #expect(regions.trailing.minY == 120)
  }

  @Test("A hidden panel hands its space back to both areas")
  func hiddenPanel() {
    let sheet = narrow(panel: .zero)
    #expect(sheet.aligned.maxY == 818)
    #expect(sheet.aligned.height == 759)

    let corner = wide(panel: .zero)
    // The column stays the panel's width, so content in it does not jump when
    // the panel comes back.
    #expect(corner.aligned == CGRect(x: 16, y: 16, width: 340, height: 868))
    #expect(corner.trailing.minX == 16)
  }
}

@Suite("Keyboard expansion")
struct KeyboardExpansionTests {

  @Test("The keyboard raises the sheet, and its going puts back the detent it left")
  func roundTrip() {
    var expansion = KeyboardExpansion()
    var detent = Detent.half
    expansion.expand(&detent, to: .full)
    #expect(detent == .full)
    expansion.restore(&detent, from: .full)
    #expect(detent == .half)
    #expect(expansion.restoring == nil)
  }

  @Test("A sheet the keyboard found already at the top stays there")
  func alreadyExpanded() {
    var expansion = KeyboardExpansion()
    var detent = Detent.full
    expansion.expand(&detent, to: .full)
    expansion.restore(&detent, from: .full)
    #expect(detent == .full)
  }

  @Test("A sheet dragged elsewhere with the keyboard up stays where it was dragged")
  func draggedWithKeyboardUp() {
    var expansion = KeyboardExpansion()
    var detent = Detent.minimized
    expansion.expand(&detent, to: .full)
    detent = .half
    expansion.restore(&detent, from: .full)
    #expect(detent == .half)
    #expect(expansion.restoring == nil)
  }

  @Test("A keyboard that never raised the sheet changes nothing as it goes")
  func restoreWithoutExpand() {
    var expansion = KeyboardExpansion()
    var detent = Detent.full
    expansion.restore(&detent, from: .full)
    #expect(detent == .full)
  }
}

@Suite("Tab bar layout")
struct TabBarLayoutTests {

  @Test("Equal columns while the widest tab fits one")
  func equalColumns() {
    #expect(TabBarLayout.columnWidths(for: [40, 70, 50, 60], filling: 400) == [100, 100, 100, 100])
  }

  @Test("A tab wider than its share keeps its width; the rest share what is left")
  func widerTabsKeepTheirWidth() {
    // A share of 60 is too narrow for the 70; the 170 left over the other three is too
    // narrow for the 60; the last two split the remaining 110.
    #expect(TabBarLayout.columnWidths(for: [40, 70, 50, 60], filling: 240) == [55, 70, 55, 60])
  }

  @Test("At exactly the tabs' own widths, every tab gets its own width")
  func naturalWidths() {
    #expect(TabBarLayout.columnWidths(for: [40, 70, 50, 60], filling: 220) == [40, 70, 50, 60])
  }

  @Test("Never narrower than a tab asks for")
  func neverSqueezes() {
    #expect(TabBarLayout.columnWidths(for: [40, 70, 50, 60], filling: 100) == [40, 70, 50, 60])
  }

  @Test("No tabs, no columns")
  func empty() {
    #expect(TabBarLayout.columnWidths(for: [], filling: 300).isEmpty)
  }
}
