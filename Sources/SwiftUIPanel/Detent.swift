import CoreGraphics

/// A resting height for the panel, as a fraction of the height available to it
/// — the container less its safe areas and margins.
///
/// Being a fraction of the *available* height keeps a set meaningful at any
/// size: `.full` still leaves the top inset clear rather than covering the
/// display.
public struct Detent: Equatable, Hashable, Sendable {

  /// Only the bar slot. Never resolves shorter than the bar itself.
  public static let minimized = Detent(fraction: 0)
  /// Half open.
  public static let half = Detent(fraction: 0.5)
  /// Everything the safe area and margins allow.
  public static let full = Detent(fraction: 1)

  /// The three levels above.
  public static let defaultSet = [minimized, half, full]

  public let fraction: CGFloat

  /// Clamps `fraction` to `0...1`.
  public init(fraction: CGFloat) {
    self.fraction = min(max(fraction, 0), 1)
  }
}
