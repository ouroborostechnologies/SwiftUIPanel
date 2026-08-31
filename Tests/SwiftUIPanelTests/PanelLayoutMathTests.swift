import SwiftUI
@testable import SwiftUIPanel
import Testing

@Suite("Sheet layout")
struct SheetLayoutTests {
  private let layout = SheetLayout(availableHeight: 800, detents: Detent.defaultSet, chromeHeight: 64)

  @Test("Detent heights are fractions of the container, floored at the chrome")
  func heights() {
    // .minimized is fraction 0: exactly the chrome — the tab bar, no content.
    #expect(layout.height(of: .minimized) == 64)
    #expect(layout.height(of: .half) == 400)
    #expect(layout.height(of: .full) == 800)
    #expect(layout.smallest == .minimized)
    #expect(layout.largest == .full)
    let shuffled = SheetLayout(availableHeight: 800, detents: [.full, .minimized, .half])
    #expect(shuffled.detents == [.minimized, .half, .full])
  }

  @Test("A tap on the collapsed sheet's tab bar opens it to half, or the next detent up")
  func openedFromCollapsed() {
    #expect(layout.openedFromCollapsed == .half)
    let noHalf = SheetLayout(availableHeight: 800, detents: [.minimized, .full])
    #expect(noHalf.openedFromCollapsed == .full)
    let only = SheetLayout(availableHeight: 800, detents: [.minimized])
    #expect(only.openedFromCollapsed == .minimized)
  }

  @Test("An empty detent set falls back to half rather than crashing")
  func emptyDetents() {
    let layout = SheetLayout(availableHeight: 800, detents: [])
    #expect(layout.detents == [.half])
  }

  @Test("Dragging up grows the sheet; down shrinks it")
  func dragDirection() {
    #expect(layout.displayedHeight(resting: .half, dragTranslation: -100) == 500)
    #expect(layout.displayedHeight(resting: .half, dragTranslation: 100) == 300)
  }

  @Test("Past the end detents the sheet rubber-bands")
  func rubberBand() {
    let over = layout.displayedHeight(resting: .full, dragTranslation: -100)
    #expect(abs(over - (800 + 20)) < 1e-9)
    let under = layout.displayedHeight(resting: .minimized, dragTranslation: 100)
    #expect(abs(under - (64 - 20)) < 1e-9)
  }

  @Test("Snapping follows the projected stop, so a short fast flick changes detent")
  func velocitySnapping() {
    // Lifted after 30pt, but the projection says it would have travelled 250.
    #expect(layout.snappedDetent(resting: .half, predictedTranslation: -250) == .full)
    #expect(layout.snappedDetent(resting: .half, predictedTranslation: 250) == .minimized)
    // A slow drag that would stop near where it is stays put.
    #expect(layout.snappedDetent(resting: .half, predictedTranslation: 40) == .half)
  }

  @Test("A flick past the last detent lands on it")
  func overshoot() {
    #expect(layout.snappedDetent(resting: .half, predictedTranslation: -2000) == .full)
    #expect(layout.snappedDetent(resting: .full, predictedTranslation: 5000) == .minimized)
  }

  @Test("Margins collapse only over the final approach to .full")
  func fullScreenProgress() {
    #expect(layout.fullScreenProgress(displayedHeight: 400) == 0)
    #expect(layout.fullScreenProgress(displayedHeight: 800 - SheetLayout.edgeCollapseDistance) == 0)
    #expect(abs(layout.fullScreenProgress(displayedHeight: 800 - SheetLayout.edgeCollapseDistance / 2) - 0.5) < 1e-9)
    #expect(layout.fullScreenProgress(displayedHeight: 800) == 1)
    // Rubber-banding past the top stays clamped.
    #expect(layout.fullScreenProgress(displayedHeight: 820) == 1)
  }

  @Test("A detent set capped short of .full keeps its margins")
  func noCollapseWithoutFull() {
    let capped = SheetLayout(availableHeight: 800, detents: [.minimized, .half])
    #expect(capped.fullScreenProgress(displayedHeight: 400) == 0)
    #expect(capped.fullScreenProgress(displayedHeight: 800) == 0)
  }
}

@Suite("Corner layout")
struct CornerLayoutTests {
  private func layout(availableHeight: CGFloat = 500, availableWidth: CGFloat = 900) -> CornerLayout {
    CornerLayout(configuredHeightRange: 160 ... 600, configuredWidthRange: 280 ... 520,
                 availableHeight: availableHeight, availableWidth: availableWidth)
  }

  @Test("The window caps the configured maximum height")
  func windowCapsHeight() {
    #expect(layout().effectiveHeightRange == 160 ... 500)
    #expect(layout().clampedHeight(900) == 500)
    #expect(layout().clampedHeight(10) == 160)
    #expect(layout().clampedHeight(300) == 300)
  }

  @Test("Width is capped by its own range and by the room beside the button stack")
  func widthCaps() {
    #expect(layout().effectiveWidthRange == 280 ... 520)
    #expect(layout().clampedWidth(800) == 520)
    #expect(layout(availableWidth: 400).clampedWidth(800) == 400)
    #expect(layout().clampedWidth(100) == 280)
  }

  @Test("A window smaller than the minimum never inverts a range")
  func tinyWindow() {
    let tiny = layout(availableHeight: 100, availableWidth: 100)
    #expect(tiny.effectiveHeightRange == 160 ... 160)
    #expect(tiny.effectiveWidthRange == 280 ... 280)
  }

  @Test("A vertical resize snaps to the detents of the available height, by projection")
  func verticalSnapping() {
    // Available 500 → minimized 80 (clamped up to 160), half 250, full 500.
    let layout = layout()
    #expect(layout.snapHeights(for: Detent.defaultSet) == [160, 250, 500])
    #expect(layout.snappedHeight(from: 250, predictedTranslation: 200, detents: Detent.defaultSet) == 500)
    #expect(layout.snappedHeight(from: 250, predictedTranslation: -30, detents: Detent.defaultSet) == 250)
    #expect(layout.snappedHeight(from: 480, predictedTranslation: -300, detents: Detent.defaultSet) == 160)
    // No detents: just clamped.
    #expect(layout.snappedHeight(from: 300, predictedTranslation: 50, detents: []) == 350)
  }

  @Test("Each grip moves only its own axes")
  func grips() {
    let start = CGSize(width: 340, height: 420)
    let drag = CGSize(width: 50, height: -30)
    #expect(ResizeEdge.trailing.apply(drag, to: start) == CGSize(width: 390, height: 420))
    #expect(ResizeEdge.bottom.apply(drag, to: start) == CGSize(width: 340, height: 390))
    #expect(ResizeEdge.bottomTrailing.apply(drag, to: start) == CGSize(width: 390, height: 390))
  }
}

@Suite("Panel insets")
struct PanelInsetsTests {
  @Test("A bottom sheet covers its clearance and height, plus a taskbar and the gap")
  func bottomSheet() {
    #expect(PanelInsets.bottomSheet(sheetHeight: 300, taskbarHeight: nil, gap: 8).bottom == 300)
    #expect(PanelInsets.bottomSheet(sheetHeight: 300, taskbarHeight: nil, gap: 8, bottomClearance: 46).bottom == 346)
    #expect(PanelInsets.bottomSheet(sheetHeight: 96, taskbarHeight: 52, gap: 8).bottom == 156)
    #expect(PanelInsets.bottomSheet(sheetHeight: 96, taskbarHeight: 0, gap: 8).bottom == 96)
    // A hidden sheet covers nothing, clearance included.
    #expect(PanelInsets.bottomSheet(sheetHeight: 0, taskbarHeight: nil, gap: 8, bottomClearance: 46).bottom == 0)
  }

  @Test("A corner panel covers a leading column and nothing else")
  func corner() {
    let insets = PanelInsets.floatingCorner(leadingInset: 20, width: 340)
    #expect(insets.leading == 360)
    #expect(insets.top == 0 && insets.bottom == 0 && insets.trailing == 0)
  }
}

@Suite("Chrome insets")
struct ChromeInsetsTests {
  @Test("The margin from each edge, unless the safe area asks for more")
  func safeAreaWins() {
    // iPhone landscape: Dynamic Island at the sides, home indicator below.
    let landscape = EdgeInsets(chromeSafe: EdgeInsets(top: 0, leading: 59, bottom: 21, trailing: 59), margin: 16)
    #expect(landscape == EdgeInsets(top: 16, leading: 59, bottom: 21, trailing: 59))
    // No safe area at all (a Mac window): the margin everywhere.
    let none = EdgeInsets(chromeSafe: EdgeInsets(), margin: 16)
    #expect(none == EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
  }
}

@Suite("Layout mode")
struct LayoutModeTests {
  @Test("An override always wins")
  func override() {
    #expect(PlatformIdiom.resolve(override: .bottomSheet, width: 2000, breakpoints: .default) == .bottomSheet)
    #expect(PlatformIdiom.resolve(override: .floatingCorner, width: 300, breakpoints: .default) == .floatingCorner)
  }

  #if os(macOS)
  @Test("Before layout, the Mac starts as a corner panel")
  func mac() {
    #expect(PlatformIdiom.resolve(override: nil, width: 0, breakpoints: .default) == .floatingCorner)
  }
  #endif
}

@Suite("Detents")
struct DetentTests {
  @Test("Fractions are clamped to the unit interval")
  func clamped() {
    #expect(Detent(fraction: 1.5).fraction == 1)
    #expect(Detent(fraction: -1).fraction == 0)
  }
}


// MARK: - Breakpoints

@Suite("Breakpoints")
struct PanelLayoutBreakpointTests {

  @Test("The mode follows the window width")
  func modeByWidth() {
    let breakpoints = PanelLayoutBreakpoints(narrowestFloatingWidth: 700)
    #expect(breakpoints.mode(for: 390) == .bottomSheet)
    #expect(breakpoints.mode(for: 699) == .bottomSheet)
    #expect(breakpoints.mode(for: 700) == .floatingCorner)
    #expect(breakpoints.mode(for: 2000) == .floatingCorner)
  }

  @Test("An override wins, and a zero width falls back to the device's natural mode")
  func overrideAndFallback() {
    var configuration = Configuration()
    configuration.layoutModeOverride = .bottomSheet
    #expect(LayoutMode.resolve(width: 2000, configuration: configuration) == .bottomSheet)
    configuration.layoutModeOverride = nil
    #if os(macOS)
    #expect(LayoutMode.resolve(width: 0, configuration: configuration) == .floatingCorner)
    #endif
  }
}


// MARK: - Taskbar placement

@Suite("Taskbar span")
struct TaskbarSpanTests {

  /// A 1400pt Mac window: a 340pt panel one 16pt margin in, and a 36pt button
  /// stack one margin from the trailing edge.
  private func span(containerWidth: CGFloat = 1400, panelWidth: CGFloat? = 340,
                    preferredWidth: CGFloat = 560) -> TaskbarSpan {
    TaskbarSpan(containerWidth: containerWidth,
                leading: panelWidth.map { 16 + $0 + 16 } ?? 16,
                trailing: containerWidth - 16 - (36 + 16),
                preferredWidth: preferredWidth)
  }

  @Test("With room on both sides the taskbar is centred on the window")
  func centred() {
    let span = span()
    #expect(span.width == 560)
    #expect(span.originX == 420)
    // Centred means centred: equal room either side of it.
    #expect(span.originX == span.containerWidth - (span.originX + span.width))
  }

  @Test("A panel that reaches past the centre slides the taskbar clear of it")
  func clearsPanel() {
    // iPhone landscape: the strip is barely wider than the taskbar, so
    // centring would put it under the panel.
    let span = span(containerWidth: 874, panelWidth: 340, preferredWidth: 560)
    #expect(span.leading == 372)
    #expect(span.trailing == 806)
    #expect(span.width == 434)
    #expect(span.originX == 372)
  }

  @Test("A strip narrower than the taskbar caps its width rather than overhanging")
  func cappedByStrip() {
    let span = span(containerWidth: 900, panelWidth: 520, preferredWidth: 560)
    #expect(span.width == 280)
    #expect(span.originX == 552)
    #expect(span.originX + span.width <= span.trailing)
  }

  @Test("Hiding the panel frees the leading side and the taskbar recentres")
  func panelHidden() {
    let span = span(containerWidth: 874, panelWidth: nil, preferredWidth: 560)
    #expect(span.width == 560)
    #expect(span.originX == 157)
  }

  @Test("No room at all leaves no taskbar rather than a negative one")
  func noRoom() {
    let span = TaskbarSpan(containerWidth: 400, leading: 380, trailing: 340, preferredWidth: 560)
    #expect(span.width == 0)
    #expect(span.originX == 380)
  }
}
