import SwiftUI

/// The visual language every floating surface shares — panel, taskbar, and
/// overlay buttons — so a consumer themes the whole package in one place.
public struct PanelStyle {

  /// The panel's and taskbar's background.
  public var material: Material
  /// The overlay buttons' background; lighter, so the content reads through.
  public var buttonMaterial: Material
  /// Panel and taskbar corners, continuous style.
  public var cornerRadius: CGFloat
  /// Overlay buttons are circles of this diameter, scaled with the user's
  /// type size.
  public var buttonDiameter: CGFloat
  public var shadowRadius: CGFloat
  public var shadowOpacity: Double
  public var shadowYOffset: CGFloat
  /// The chrome's distance from the display's edges on iPhone. Where the
  /// safe area asks for more (Dynamic Island, home indicator), it wins.
  public var edgeMarginCompact: CGFloat
  /// The same, on iPad and Mac.
  public var edgeMarginRegular: CGFloat
  /// Applied to every detent and resize transition.
  public var animation: Animation

  public init(
    material: Material = .regularMaterial,
    buttonMaterial: Material = .ultraThinMaterial,
    cornerRadius: CGFloat = 16,
    buttonDiameter: CGFloat = 36,
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

  public static let `default` = PanelStyle()

  func edgeMargin(for mode: LayoutMode) -> CGFloat {
    mode == .bottomSheet ? edgeMarginCompact : edgeMarginRegular
  }
}
