import SwiftUI

/// The visual language every floating surface shares — panel, taskbar, and
/// map buttons — so a consumer themes the whole package in one place.
public struct FloatingChromeStyle {

  /// The panel's and taskbar's background.
  public var material: Material
  /// The map buttons' background; lighter, so the map reads through.
  public var buttonMaterial: Material
  /// Panel and taskbar corners, continuous style.
  public var cornerRadius: CGFloat
  /// Map buttons are circles of this diameter.
  public var buttonDiameter: CGFloat
  public var shadowRadius: CGFloat
  public var shadowOpacity: Double
  public var shadowYOffset: CGFloat
  /// Distance from the safe area on iPhone.
  public var edgeMarginCompact: CGFloat
  /// Distance from the safe area on iPad and Mac.
  public var edgeMarginRegular: CGFloat
  /// Applied to every detent and resize transition.
  public var animation: Animation

  public init(
    material: Material = .regularMaterial,
    buttonMaterial: Material = .ultraThinMaterial,
    cornerRadius: CGFloat = 16,
    buttonDiameter: CGFloat = 44,
    shadowRadius: CGFloat = 8,
    shadowOpacity: Double = 0.15,
    shadowYOffset: CGFloat = 2,
    edgeMarginCompact: CGFloat = 12,
    edgeMarginRegular: CGFloat = 16,
    animation: Animation = .spring(response: 0.4, dampingFraction: 0.85)
  ) {
    self.material = material
    self.buttonMaterial = buttonMaterial
    self.cornerRadius = cornerRadius
    self.buttonDiameter = buttonDiameter
    self.shadowRadius = shadowRadius
    self.shadowOpacity = shadowOpacity
    self.shadowYOffset = shadowYOffset
    self.edgeMarginCompact = edgeMarginCompact
    self.edgeMarginRegular = edgeMarginRegular
    self.animation = animation
  }

  public static let `default` = FloatingChromeStyle()

  func edgeMargin(for mode: PanelLayoutMode) -> CGFloat {
    mode == .bottomSheet ? edgeMarginCompact : edgeMarginRegular
  }
}
