import CoreGraphics

/// A resting height for the iPhone bottom sheet, as a fraction of the
/// container's full height.
public struct FloatingPanelDetent: Equatable, Hashable, Sendable {

  /// Just the tab bar and a sliver of content; used when a taskbar needs room.
  public static let minimized = FloatingPanelDetent(fraction: 0.12)
  /// The default resting state.
  public static let half = FloatingPanelDetent(fraction: 0.5)
  /// Covers the screen, bar the top safe area.
  public static let full = FloatingPanelDetent(fraction: 0.98)

  public static let defaultSet = [minimized, half, full]

  public let fraction: CGFloat

  public init(fraction: CGFloat) {
    self.fraction = min(max(fraction, 0), 1)
  }
}
