import SwiftUI

/// The panel's heights, given the room it has.
///
/// Both layouts read it: a detent is the panel's resting height whether it
/// sheets or floats. Kept out of the views so snapping — the part that decides
/// whether a panel feels right — is unit-tested rather than eyeballed.
struct PanelHeights: Equatable {

  /// The container less its safe areas and margins.
  let availableHeight: CGFloat
  /// Ascending by fraction, and never empty.
  let detents: [Detent]
  /// The bar slot's measured height. No detent resolves below it, so
  /// `.minimized` shows exactly the bar.
  let barHeight: CGFloat
  private let rubberBandFactor: CGFloat
  private let dissolveDistance: CGFloat

  init(availableHeight: CGFloat, detents: [Detent], barHeight: CGFloat, style: PanelStyle) {
    self.availableHeight = max(availableHeight, 0)
    let ascending = detents.sorted { $0.fraction < $1.fraction }
    self.detents = ascending.isEmpty ? [.half] : ascending
    self.barHeight = max(barHeight, 0)
    self.rubberBandFactor = style.rubberBandFactor
    self.dissolveDistance = style.marginDissolveDistance
  }

  var smallest: Detent { detents[0] }
  var largest: Detent { detents[detents.count - 1] }

  /// The height `detent` rests at.
  func height(of detent: Detent) -> CGFloat {
    max(detent.fraction * availableHeight, barHeight)
  }

  /// `detent` if the set contains it, else the smallest.
  func resolved(_ detent: Detent) -> Detent {
    detents.contains(detent) ? detent : smallest
  }

  /// The height to draw mid-drag, following the finger past the end detents at
  /// a reduced rate.
  ///
  /// - Parameter translation: positive downwards, so a finger moving down
  ///   shrinks a sheet. A resize of the wide panel's bottom edge, where down
  ///   grows it, negates it first.
  func height(from resting: Detent, draggedBy translation: CGFloat) -> CGFloat {
    let raw = height(of: resting) - translation
    if raw > maxHeight { return maxHeight + (raw - maxHeight) * rubberBandFactor }
    if raw < minHeight { return minHeight - (minHeight - raw) * rubberBandFactor }
    return raw
  }

  /// The detent a released drag lands on.
  ///
  /// Decided by where the panel *would* stop if it kept its velocity, not by
  /// where the finger lifted, so a fast flick commits to the next detent even
  /// when the distance was short.
  ///
  /// - Parameter projected: `DragGesture.Value.predictedEndTranslation.height`.
  func snappedDetent(from resting: Detent, projecting projected: CGFloat) -> Detent {
    let stop = height(of: resting) - projected
    return detents.min { abs(height(of: $0) - stop) < abs(height(of: $1) - stop) } ?? resting
  }

  /// A focused panel's height: what its content asks for, up to all of the
  /// available height, with no detent in it. Until the content has been
  /// measured, the resting detent's — so the panel moves once, to the right
  /// height, rather than collapsing first.
  func fittedHeight(_ content: CGFloat?, resting: Detent) -> CGFloat {
    guard let content else { return height(of: resting) }
    return min(max(content, 0), availableHeight)
  }

  /// How far a sheet is into going edge-to-edge: 0 through most of its travel,
  /// rising to 1 over the last `marginDissolveDistance` before the top detent.
  ///
  /// A set that stops short of `.full` never reports progress, so a sheet
  /// capped below the top keeps its margins.
  func dissolveProgress(atHeight height: CGFloat) -> CGFloat {
    guard largest.fraction >= 1, maxHeight > dissolveDistance else { return 0 }
    return min(max(1 - (maxHeight - height) / dissolveDistance, 0), 1)
  }

  private var minHeight: CGFloat { height(of: smallest) }
  private var maxHeight: CGFloat { height(of: largest) }
}

/// What a docked keyboard does to a sheet's detent: raises it while the
/// keyboard is up, and puts it back after.
struct KeyboardExpansion: Equatable {

  /// Where the panel rested before the keyboard raised it. `nil` when the
  /// keyboard found it already at the top, so there is nothing to put back.
  private(set) var restoring: Detent?

  /// Raises `detent` to `target`, remembering where it was.
  mutating func expand(_ detent: inout Detent, to target: Detent) {
    guard detent != target else { return }
    restoring = detent
    detent = target
  }

  /// Puts back the detent the keyboard raised — unless the panel has been dragged
  /// somewhere else meanwhile, in which case it stays where it was put.
  mutating func restore(_ detent: inout Detent, from target: Detent) {
    defer { restoring = nil }
    guard let restoring, detent == target else { return }
    detent = restoring
  }
}

/// The wide panel's widths — the one dimension it resizes freely.
struct PanelWidths: Equatable {

  let configuredRange: ClosedRange<CGFloat>
  /// The container less its margins and safe areas.
  let available: CGFloat

  /// `configuredRange`, capped by the room actually available.
  var effectiveRange: ClosedRange<CGFloat> {
    let lower = max(configuredRange.lowerBound, 0)
    return lower ... max(lower, min(configuredRange.upperBound, available))
  }

  func clamped(_ width: CGFloat) -> CGFloat {
    min(max(width, effectiveRange.lowerBound), effectiveRange.upperBound)
  }
}

/// Which grip of the wide panel is being dragged.
enum ResizeEdge {
  case trailing
  case bottom
  case bottomTrailing

  var affectsWidth: Bool { self != .bottom }
  var affectsHeight: Bool { self != .trailing }
}

/// Where the toast sits along the container's top edge on a wide layout.
///
/// It belongs to the container, so it is centred on the container — then slid,
/// never squeezed, far enough to clear the panel beside it. Only a strip
/// narrower than the toast wants costs it width.
struct ToastSpan: Equatable {

  let containerWidth: CGFloat
  /// The leading edge of the strip left free beside the panel.
  let stripLeading: CGFloat
  /// Its trailing edge.
  let stripTrailing: CGFloat
  /// The width the toast would take given the room.
  let preferredWidth: CGFloat

  var width: CGFloat { max(min(preferredWidth, stripTrailing - stripLeading), 0) }

  /// The toast's offset from the container's leading edge.
  var originX: CGFloat {
    let centred = (containerWidth - width) / 2
    return min(max(centred, stripLeading), max(stripTrailing - width, stripLeading))
  }
}

extension EdgeInsets {

  /// Where the chrome sits relative to each container edge: one `margin`,
  /// grown only where `safeArea` asks for more.
  ///
  /// Nothing is device-checked — the safe area already encodes the hardware,
  /// so the margin reads the same on every side with nothing in the way.
  init(margin: CGFloat, clearing safeArea: EdgeInsets) {
    self.init(top: max(safeArea.top, margin),
              leading: max(safeArea.leading, margin),
              bottom: max(safeArea.bottom, margin),
              trailing: max(safeArea.trailing, margin))
  }
}

/// The two free-space containers the consumer fills, derived from the same
/// numbers the panel was drawn with — so an area can never overlap the panel
/// it is measured from.
///
/// Both are plain rectangles. Neither knows anything about what goes in it:
/// the consumer aligns their own content inside with the standard frame
/// alignments.
struct PanelRegions: Equatable {

  let mode: LayoutMode
  let container: CGSize
  /// Where the chrome sits relative to each container edge.
  let edge: EdgeInsets
  /// The panel's frame. Empty when the panel is off screen, which hands its
  /// space back to the areas rather than leaving a hole where it was.
  let panelFrame: CGRect
  /// The width of the panel's column on wide layouts, whether or not the panel
  /// is on screen — so the aligned area keeps that column either way.
  let panelWidth: CGFloat
  /// Where an area may start at the top: below the toast wherever one is
  /// showing, and at the top inset when none is.
  let contentTop: CGFloat
  /// Between the panel and an area measured from it.
  let spacing: CGFloat
  /// The band of height across which the aligned area fades as the panel grows
  /// into it.
  let fadeDistance: CGFloat

  /// The area sharing the panel's column, anchored to the edge the panel is
  /// *not* anchored to: above a bottom sheet, below a floating corner panel.
  var aligned: CGRect {
    switch mode {
    case .bottomSheet:
      // Full width, from under the toast down to the sheet's top edge.
      let bottom = panelFrame.isEmpty ? bottomLimit : panelFrame.minY - spacing
      return rect(leading: edge.leading, trailing: container.width - edge.trailing,
                  top: contentTop, bottom: bottom)
    case .floatingCorner:
      // The panel's own column, from under the panel down to the bottom inset.
      let top = panelFrame.isEmpty ? contentTop : panelFrame.maxY + spacing
      return rect(leading: edge.leading, trailing: edge.leading + panelWidth,
                  top: top, bottom: bottomLimit)
    }
  }

  /// The area on the panel's trailing side.
  ///
  /// On a wide layout that is the strip between the panel and the container's
  /// trailing edge. A bottom sheet spans the full width and leaves no such
  /// strip, so there the area is the whole inset container and floats over the
  /// sheet — which is where a column of controls belongs on either layout.
  var trailing: CGRect {
    let leading = mode == .floatingCorner && !panelFrame.isEmpty
      ? panelFrame.maxX + spacing
      : edge.leading
    return rect(leading: leading, trailing: container.width - edge.trailing,
                top: contentTop, bottom: bottomLimit)
  }

  /// How solid the aligned area is: full until the panel has grown to within
  /// `fadeDistance` of filling its column, then out.
  ///
  /// Read from the area's live height rather than from the detent, so a panel
  /// dragged open fades it out continuously and dragging back down fades it in
  /// again.
  var alignedOpacity: Double {
    guard fadeDistance > 0 else { return aligned.height > 0 ? 1 : 0 }
    return Double(min(max(aligned.height / fadeDistance, 0), 1))
  }

  private var bottomLimit: CGFloat { container.height - edge.bottom }

  /// A rect from four edges, collapsed rather than inverted when they cross.
  private func rect(leading: CGFloat, trailing: CGFloat,
                    top: CGFloat, bottom: CGFloat) -> CGRect {
    CGRect(x: leading, y: top,
           width: max(trailing - leading, 0), height: max(bottom - top, 0))
  }
}

/// What the panel covers, for the content underneath.
enum ChromeInsets {

  /// The edge the panel claims, derived from the same frame the panel is drawn
  /// at — so the two cannot disagree.
  ///
  /// The panel covers the bottom on narrow and a leading column on wide. Only
  /// the panel counts: the toast and the two free-space containers float over
  /// the content rather than displacing it, so showing or hiding any of them
  /// leaves the content where it was. An empty frame is a hidden panel and covers nothing.
  static func covering(panel: CGRect, in container: CGSize, mode: LayoutMode) -> EdgeInsets {
    var insets = EdgeInsets()
    guard !panel.isEmpty else { return insets }
    switch mode {
    case .bottomSheet: insets.bottom = container.height - panel.minY
    case .floatingCorner: insets.leading = panel.maxX
    }
    return insets
  }
}
