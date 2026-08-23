import SwiftUI

/// The bottom sheet's geometry, as pure arithmetic over the height available
/// to it (the container less safe areas and margins).
///
/// Kept out of the views so that detent snapping — the part that decides
/// whether a sheet "feels right" — is unit-tested rather than eyeballed.
struct SheetLayout: Equatable {

  let availableHeight: CGFloat
  /// Ascending by fraction.
  let detents: [FloatingPanelDetent]

  init(availableHeight: CGFloat, detents: [FloatingPanelDetent]) {
    self.availableHeight = max(availableHeight, 0)
    let sorted = detents.sorted { $0.fraction < $1.fraction }
    self.detents = sorted.isEmpty ? [.half] : sorted
  }

  var smallest: FloatingPanelDetent { detents[0] }
  var largest: FloatingPanelDetent { detents[detents.count - 1] }

  func height(of detent: FloatingPanelDetent) -> CGFloat {
    detent.fraction * availableHeight
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

/// The corner panel's size limits, capped by the window it floats in.
struct CornerLayout: Equatable {

  let configuredHeightRange: ClosedRange<CGFloat>
  let configuredWidthRange: ClosedRange<CGFloat>
  /// Container height less margins and safe areas.
  let availableHeight: CGFloat
  /// Container width less margins, safe areas, and the button stack.
  let availableWidth: CGFloat

  var effectiveHeightRange: ClosedRange<CGFloat> { Self.cap(configuredHeightRange, to: availableHeight) }
  var effectiveWidthRange: ClosedRange<CGFloat> { Self.cap(configuredWidthRange, to: availableWidth) }

  func clampedHeight(_ height: CGFloat) -> CGFloat { Self.clamp(height, to: effectiveHeightRange) }
  func clampedWidth(_ width: CGFloat) -> CGFloat { Self.clamp(width, to: effectiveWidthRange) }

  func clamped(_ size: CGSize) -> CGSize {
    CGSize(width: clampedWidth(size.width), height: clampedHeight(size.height))
  }

  /// The heights a vertical resize snaps to: the detents applied to the
  /// available height, clamped into the effective range.
  func snapHeights(for detents: [FloatingPanelDetent]) -> [CGFloat] {
    Array(Set(detents.map { clampedHeight($0.fraction * availableHeight) })).sorted()
  }

  /// Where a vertical resize lands on release — decided by the projected stop
  /// (`predictedTranslation`), so a flick commits to the next detent even when
  /// the drag was short. With no detents the height is simply clamped.
  func snappedHeight(from height: CGFloat, predictedTranslation: CGFloat, detents: [FloatingPanelDetent]) -> CGFloat {
    let projected = clampedHeight(height + predictedTranslation)
    let candidates = snapHeights(for: detents)
    return candidates.min { abs($0 - projected) < abs($1 - projected) } ?? projected
  }

  private static func cap(_ range: ClosedRange<CGFloat>, to available: CGFloat) -> ClosedRange<CGFloat> {
    let lower = max(range.lowerBound, 0)
    let upper = max(lower, min(range.upperBound, available))
    return lower ... upper
  }

  private static func clamp(_ value: CGFloat, to range: ClosedRange<CGFloat>) -> CGFloat {
    min(max(value, range.lowerBound), range.upperBound)
  }
}

/// Which grip of the corner panel is being dragged.
enum ResizeEdge {
  case trailing
  case bottom
  case bottomTrailing

  var affectsWidth: Bool { self != .bottom }
  var affectsHeight: Bool { self != .trailing }

  /// The drag translation applied to the panel's size.
  func apply(_ translation: CGSize, to start: CGSize) -> CGSize {
    CGSize(width: start.width + (affectsWidth ? translation.width : 0),
           height: start.height + (affectsHeight ? translation.height : 0))
  }
}

/// What the panel covers, for the content underneath.
enum PanelInsets {

  /// A bottom sheet covers, from the content's bottom edge: the safe area and
  /// margin it floats above, its own height, and a taskbar stacked above it.
  static func bottomSheet(sheetHeight: CGFloat, taskbarHeight: CGFloat?, gap: CGFloat,
                          bottomClearance: CGFloat = 0) -> EdgeInsets {
    guard sheetHeight > 0 || (taskbarHeight ?? 0) > 0 else { return EdgeInsets() }
    var bottom = bottomClearance + max(sheetHeight, 0)
    if let taskbarHeight, taskbarHeight > 0 { bottom += taskbarHeight + gap }
    return EdgeInsets(top: 0, leading: 0, bottom: bottom, trailing: 0)
  }

  /// A corner panel covers a column on the leading edge: safe area, margin,
  /// and its own width.
  static func floatingCorner(safeLeading: CGFloat, margin: CGFloat, width: CGFloat) -> EdgeInsets {
    EdgeInsets(top: 0, leading: safeLeading + margin + width, bottom: 0, trailing: 0)
  }
}
