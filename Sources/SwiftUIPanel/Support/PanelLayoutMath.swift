import SwiftUI

/// The bottom sheet's geometry, as pure arithmetic over the container height.
///
/// Kept out of the views so that detent snapping — the part that decides
/// whether a sheet "feels right" — is unit-tested rather than eyeballed.
struct SheetLayout: Equatable {

  let containerHeight: CGFloat
  /// Ascending by fraction.
  let detents: [FloatingPanelDetent]

  init(containerHeight: CGFloat, detents: [FloatingPanelDetent]) {
    self.containerHeight = containerHeight
    let sorted = detents.sorted { $0.fraction < $1.fraction }
    self.detents = sorted.isEmpty ? [.half] : sorted
  }

  var smallest: FloatingPanelDetent { detents[0] }
  var largest: FloatingPanelDetent { detents[detents.count - 1] }

  func height(of detent: FloatingPanelDetent) -> CGFloat {
    detent.fraction * containerHeight
  }

  var minHeight: CGFloat { height(of: smallest) }
  var maxHeight: CGFloat { height(of: largest) }

  /// How far past the end detents the sheet follows a finger. Past the
  /// limits it moves a fifth as far, like a system sheet.
  static let rubberBandFactor: CGFloat = 0.2

  /// The sheet's on-screen height while a drag is in progress.
  ///
  /// - Parameter dragTranslation: the gesture's vertical translation, positive
  ///   downwards (so a finger moving down shrinks the sheet).
  func displayedHeight(resting: FloatingPanelDetent, dragTranslation: CGFloat) -> CGFloat {
    let raw = height(of: resting) - dragTranslation
    if raw > maxHeight {
      return maxHeight + (raw - maxHeight) * Self.rubberBandFactor
    }
    if raw < minHeight {
      return minHeight - (minHeight - raw) * Self.rubberBandFactor
    }
    return raw
  }

  /// The detent a drag lands on.
  ///
  /// Decided by where the sheet *would* stop if it kept its velocity
  /// (`predictedTranslation`, from `DragGesture.Value.predictedEndTranslation`),
  /// not by where the finger lifted. A fast flick therefore commits to the
  /// next detent even when the distance was short — the behaviour people know
  /// from `UISheetPresentationController`.
  func snappedDetent(resting: FloatingPanelDetent, predictedTranslation: CGFloat) -> FloatingPanelDetent {
    let projected = height(of: resting) - predictedTranslation
    return detents.min { abs(height(of: $0) - projected) < abs(height(of: $1) - projected) } ?? resting
  }

  /// Validates a configured detent against the set.
  func contains(_ detent: FloatingPanelDetent) -> Bool {
    detents.contains(detent)
  }
}

/// The corner panel's height limits, capped by the window it floats in.
struct CornerLayout: Equatable {

  let configuredRange: ClosedRange<CGFloat>
  /// Container height less margins and safe areas.
  let availableHeight: CGFloat

  var effectiveRange: ClosedRange<CGFloat> {
    let lower = max(configuredRange.lowerBound, 0)
    let upper = max(lower, min(configuredRange.upperBound, availableHeight))
    return lower ... upper
  }

  func clamped(_ height: CGFloat) -> CGFloat {
    min(max(height, effectiveRange.lowerBound), effectiveRange.upperBound)
  }
}

/// What the panel covers, for the content underneath.
enum PanelInsets {

  /// A bottom sheet covers its own height plus a taskbar stacked above it.
  static func bottomSheet(sheetHeight: CGFloat, taskbarHeight: CGFloat?, gap: CGFloat) -> EdgeInsets {
    var bottom = max(sheetHeight, 0)
    if let taskbarHeight, taskbarHeight > 0 { bottom += taskbarHeight + gap }
    return EdgeInsets(top: 0, leading: 0, bottom: bottom, trailing: 0)
  }

  /// A corner panel covers a column on the leading edge: safe area, margin,
  /// and its own width.
  static func floatingCorner(safeLeading: CGFloat, margin: CGFloat, width: CGFloat) -> EdgeInsets {
    EdgeInsets(top: 0, leading: safeLeading + margin + width, bottom: 0, trailing: 0)
  }
}
