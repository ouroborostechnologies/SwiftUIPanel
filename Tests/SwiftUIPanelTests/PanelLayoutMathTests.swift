import SwiftUI
@testable import SwiftUIPanel
import Testing

@Suite("Sheet layout")
struct SheetLayoutTests {
  private let layout = SheetLayout(containerHeight: 800, detents: FloatingPanelDetent.defaultSet)

  @Test("Detent heights are fractions of the container, sorted ascending")
  func heights() {
    #expect(layout.height(of: .minimized) == 96)
    #expect(layout.height(of: .half) == 400)
    #expect(layout.height(of: .full) == 784)
    #expect(layout.smallest == .minimized)
    #expect(layout.largest == .full)
    let shuffled = SheetLayout(containerHeight: 800, detents: [.full, .minimized, .half])
    #expect(shuffled.detents == [.minimized, .half, .full])
  }

  @Test("An empty detent set falls back to half rather than crashing")
  func emptyDetents() {
    let layout = SheetLayout(containerHeight: 800, detents: [])
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
    #expect(abs(over - (784 + 20)) < 1e-9)
    let under = layout.displayedHeight(resting: .minimized, dragTranslation: 100)
    #expect(abs(under - (96 - 20)) < 1e-9)
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
}

@Suite("Corner layout")
struct CornerLayoutTests {
  @Test("The window caps the configured maximum")
  func windowCaps() {
    let layout = CornerLayout(configuredRange: 160 ... 600, availableHeight: 500)
    #expect(layout.effectiveRange == 160 ... 500)
    #expect(layout.clamped(900) == 500)
    #expect(layout.clamped(10) == 160)
    #expect(layout.clamped(300) == 300)
  }

  @Test("A window shorter than the minimum never inverts the range")
  func tinyWindow() {
    let layout = CornerLayout(configuredRange: 160 ... 600, availableHeight: 100)
    #expect(layout.effectiveRange == 160 ... 160)
  }
}

@Suite("Panel insets")
struct PanelInsetsTests {
  @Test("A bottom sheet covers its height, plus a taskbar and the gap")
  func bottomSheet() {
    #expect(PanelInsets.bottomSheet(sheetHeight: 300, taskbarHeight: nil, gap: 8).bottom == 300)
    #expect(PanelInsets.bottomSheet(sheetHeight: 96, taskbarHeight: 52, gap: 8).bottom == 156)
    #expect(PanelInsets.bottomSheet(sheetHeight: 96, taskbarHeight: 0, gap: 8).bottom == 96)
    #expect(PanelInsets.bottomSheet(sheetHeight: -5, taskbarHeight: nil, gap: 8).bottom == 0)
  }

  @Test("A corner panel covers a leading column and nothing else")
  func corner() {
    let insets = PanelInsets.floatingCorner(safeLeading: 4, margin: 16, width: 340)
    #expect(insets.leading == 360)
    #expect(insets.top == 0 && insets.bottom == 0 && insets.trailing == 0)
  }
}

@Suite("Layout mode")
struct LayoutModeTests {
  @Test("An override always wins")
  func override() {
    #expect(PlatformIdiom.resolve(override: .bottomSheet) == .bottomSheet)
    #expect(PlatformIdiom.resolve(override: .floatingCorner) == .floatingCorner)
  }

  #if os(macOS)
  @Test("The Mac is always a corner panel")
  func mac() {
    #expect(PlatformIdiom.resolve(override: nil) == .floatingCorner)
  }
  #endif
}

@Suite("Detents")
struct DetentTests {
  @Test("Fractions are clamped to the unit interval")
  func clamped() {
    #expect(FloatingPanelDetent(fraction: 1.5).fraction == 1)
    #expect(FloatingPanelDetent(fraction: -1).fraction == 0)
  }
}
