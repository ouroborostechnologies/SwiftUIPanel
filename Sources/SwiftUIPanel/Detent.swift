import CoreGraphics

/// A resting height for the iPhone bottom sheet, as a fraction of the height
/// available to it: the container less the safe areas (Dynamic Island, home
/// indicator) and the edge margin on both ends.
///
/// Because the fraction is of the *available* height, `.full` still leaves the
/// top safe area and margin clear — the handle stays reachable and a sliver of
/// content shows above the sheet.
public struct Detent: Equatable, Hashable, Sendable {

  /// Fully closed: just the handle and the tab bar, no content. A zero
  /// fraction resolves to the sheet's measured chrome height, never less.
  public static let minimized = Detent(fraction: 0)
  /// The default resting state.
  public static let half = Detent(fraction: 0.5)
  /// Everything the safe area and margins allow.
  public static let full = Detent(fraction: 1)

  public static let defaultSet = [minimized, half, full]

  public let fraction: CGFloat

  public init(fraction: CGFloat) {
    self.fraction = min(max(fraction, 0), 1)
  }
}
