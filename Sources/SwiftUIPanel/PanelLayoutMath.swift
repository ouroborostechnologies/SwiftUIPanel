import SwiftUI

/// The bottom sheet's geometry, as pure arithmetic over the height available
/// to it (the container less safe areas and margins).
///
/// Kept out of the views so that detent snapping — the part that decides
/// whether a sheet "feels right" — is unit-tested rather than eyeballed.
struct SheetLayout: Equatable {

  let availableHeight: CGFloat
  /// Ascending by fraction.
  let detents: [Detent]
  /// The measured height of the sheet's chrome — handle, tab bar, bottom
  /// inset. No detent resolves below it, so `.minimized` (fraction 0) shows
  /// exactly the chrome and nothing else.
  let chromeHeight: CGFloat

  init(availableHeight: CGFloat, detents: [Detent], chromeHeight: CGFloat = 0) {
    self.availableHeight = max(availableHeight, 0)
    let sorted = detents.sorted { $0.fraction < $1.fraction }
    self.detents = sorted.isEmpty ? [.half] : sorted
    self.chromeHeight = max(chromeHeight, 0)
  }

  var smallest: Detent { detents[0] }
  var largest: Detent { detents[detents.count - 1] }

  func height(of detent: Detent) -> CGFloat {
    max(detent.fraction * availableHeight, chromeHeight)
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
  func displayedHeight(resting: Detent, dragTranslation: CGFloat) -> CGFloat {
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
  func snappedDetent(resting: Detent, predictedTranslation: CGFloat) -> Detent {
    let projected = height(of: resting) - predictedTranslation
    return detents.min { abs(height(of: $0) - projected) < abs(height(of: $1) - projected) } ?? resting
  }

  /// Validates a configured detent against the set.
  func contains(_ detent: Detent) -> Bool {
    detents.contains(detent)
  }

  /// Where a tap on the collapsed sheet's tab bar opens it: `.half` when the
  /// set offers it, else the next detent up from the smallest.
  var openedFromCollapsed: Detent {
    contains(.half) ? .half : detents[min(1, detents.count - 1)]
  }

  /// The height band, below `.full`, across which the side margins collapse.
  static let edgeCollapseDistance: CGFloat = 64

  /// How far the sheet is into going full screen: 0 through most of its
  /// travel, rising to 1 over the last `edgeCollapseDistance` points before
  /// the top detent. Only a detent set that actually reaches `.full` ever
  /// reports progress — a sheet capped short of the top keeps its margins.
  ///
  /// This is what dissolves the sheet's floating-card margins into an
  /// edge-to-edge surface, live during the drag.
  func fullScreenProgress(displayedHeight: CGFloat) -> CGFloat {
    guard largest.fraction >= 1, maxHeight > Self.edgeCollapseDistance else { return 0 }
    return min(max(1 - (maxHeight - displayedHeight) / Self.edgeCollapseDistance, 0), 1)
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
  func snapHeights(for detents: [Detent]) -> [CGFloat] {
    Array(Set(detents.map { clampedHeight($0.fraction * availableHeight) })).sorted()
  }

  /// Where a vertical resize lands on release — decided by the projected stop
  /// (`predictedTranslation`), so a flick commits to the next detent even when
  /// the drag was short. With no detents the height is simply clamped.
  func snappedHeight(from height: CGFloat, predictedTranslation: CGFloat, detents: [Detent]) -> CGFloat {
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

extension EdgeInsets {
  /// Where the chrome sits relative to each display edge: one margin from the
  /// edge, grown only where the safe area itself asks for more (Dynamic
  /// Island, home indicator, notch). Nothing is device-checked — the safe
  /// area already encodes the hardware, so the margin reads the same on every
  /// side that has nothing in the way.
  init(chromeSafe safe: EdgeInsets, margin: CGFloat) {
    self.init(top: max(safe.top, margin),
              leading: max(safe.leading, margin),
              bottom: max(safe.bottom, margin),
              trailing: max(safe.trailing, margin))
  }
}

/// What the panel covers, for the content underneath.
enum PanelInsets {

  /// A bottom sheet covers, from the content's bottom edge: the safe area and
  /// margin it floats above, its own height, and a taskbar stacked above it.
  /// (At `.full` the sheet absorbs the clearance itself; the total is the same.)
  static func bottomSheet(sheetHeight: CGFloat, taskbarHeight: CGFloat?, gap: CGFloat,
                          bottomClearance: CGFloat = 0) -> EdgeInsets {
    guard sheetHeight > 0 || (taskbarHeight ?? 0) > 0 else { return EdgeInsets() }
    var bottom = bottomClearance + max(sheetHeight, 0)
    if let taskbarHeight, taskbarHeight > 0 { bottom += taskbarHeight + gap }
    return EdgeInsets(top: 0, leading: 0, bottom: bottom, trailing: 0)
  }

  /// A corner panel covers a column on the leading edge: its inset from the
  /// display plus its own width.
  static func floatingCorner(leadingInset: CGFloat, width: CGFloat) -> EdgeInsets {
    EdgeInsets(top: 0, leading: leadingInset + width, bottom: 0, trailing: 0)
  }
}

/// Where the taskbar sits along the top edge, on iPad and Mac.
///
/// It belongs to the window rather than to the panel, so it is centred on the
/// window — then slid, never squeezed, just far enough to stay clear of the
/// panel on one side and the button stack on the other. Only a strip narrower
/// than the taskbar wants costs it width.
struct TaskbarSpan: Equatable {

  /// The full window width the taskbar is centred on.
  let containerWidth: CGFloat
  /// The free strip's leading edge: the panel's trailing edge plus its gap,
  /// or the chrome inset where no panel is showing.
  let leading: CGFloat
  /// Its trailing edge: the button stack's leading edge less its gap, or the
  /// chrome inset where there is no stack.
  let trailing: CGFloat
  /// The width the taskbar would take given the room.
  let preferredWidth: CGFloat

  /// The taskbar's width: what it asks for, capped by the strip.
  var width: CGFloat { max(min(preferredWidth, trailing - leading), 0) }

  /// Its leading offset from the window's edge.
  var originX: CGFloat {
    let centred = (containerWidth - width) / 2
    return min(max(centred, leading), max(trailing - width, leading))
  }
}
