import SwiftUI

/// Every number and material the chrome draws with.
///
/// This is the one place in the package where a point value is written down;
/// layout code reads these names. Set the properties you want to change on a
/// fresh instance and assign it to `PanelController.style`.
///
/// ```swift
/// panel.style.material = .thickMaterial
/// panel.style.panelWidth = 380
/// ```
public struct PanelStyle: Sendable {

  // MARK: Surfaces

  /// The panel's and the toast's background.
  public var material: Material = .regularMaterial
  /// The buttons' background. Lighter, so content reads through them.
  public var buttonMaterial: Material = .ultraThinMaterial
  /// Panel and toast corners, and the floor under a concentric radius.
  public var cornerRadius: CGFloat = 16
  public var shadowRadius: CGFloat = 8
  public var shadowOpacity: Double = 0.15
  public var shadowYOffset: CGFloat = 2
  /// A control that is pressed, or showing an off state.
  public var dimmedOpacity: Double = 0.6

  // MARK: Spacing

  /// The chrome's distance from the container's edges on narrow layouts. Where
  /// the safe area asks for more, the safe area wins.
  public var edgeMarginCompact: CGFloat = 12
  /// The same, on wide layouts.
  public var edgeMarginRegular: CGFloat = 16
  /// Between one chrome surface and the next.
  public var surfaceSpacing: CGFloat = 8
  /// Between the button stack's children.
  public var buttonSpacing: CGFloat = 8
  /// Inside a surface, around the content it was given.
  public var surfacePaddingHorizontal: CGFloat = 12
  public var surfacePaddingVertical: CGFloat = 8

  // MARK: Sizing

  /// Buttons are circles of this diameter, scaled by the user's type size.
  public var buttonDiameter: CGFloat = 36
  /// The floor under the toast's height.
  public var minimumTouchHeight: CGFloat = 44
  /// The panel's width on wide layouts, before the consumer resizes it.
  public var panelWidth: CGFloat = 340
  /// What a width resize may reach, capped again by the room beside the button
  /// stack. Height has no equivalent: it is a detent, on both layouts.
  public var panelWidthRange: ClosedRange<CGFloat> = 280 ... 520
  /// The toast's width on wide layouts, capped by the strip left free between
  /// the panel and the button stack.
  public var toastWidth: CGFloat = 560
  /// Below this container width the panel is a bottom sheet; at or above it, a
  /// floating corner panel.
  public var narrowestFloatingWidth: CGFloat = 700
  /// The grab handle drawn at the top of a bottom sheet.
  public var dragHandleWidth: CGFloat = 36
  public var dragHandleHeight: CGFloat = 5
  /// How far into the sheet's content a drag may start, so the gesture is not
  /// confined to the handle.
  public var dragStripHeight: CGFloat = 24
  /// How far a drag must travel to be a drag rather than a tap.
  public var dragMinimumDistance: CGFloat = 2
  /// How thick the wide panel's resize grips are. They draw nothing; this is
  /// the size of the target.
  public var gripThickness: CGFloat = 10
  /// Stands in for the bar slot's height on the first layout pass, before it
  /// has been measured.
  public var barHeightEstimate: CGFloat = 76

  // MARK: Interaction

  /// How far the panel follows a drag past the end detents.
  public var rubberBandFactor: CGFloat = 0.2
  /// The band below `.full` across which a bottom sheet's margins dissolve
  /// into an edge-to-edge surface.
  public var marginDissolveDistance: CGFloat = 64
  /// Applied to every detent, resize, and visibility change.
  public var animation: Animation = .spring(response: 0.4, dampingFraction: 0.85)

  // MARK: Tabs

  // Read only by the optional tab layer, which is built on the public API and
  // so has nowhere else to keep a number.

  /// The tab bar's icon slot, scaled by the user's type size.
  public var tabIconHeight: CGFloat = 22
  /// Between a tab's icon and its label.
  public var tabLabelSpacing: CGFloat = 3
  public var tabBarPaddingTop: CGFloat = 6
  public var tabBarPaddingBottom: CGFloat = 4

  public init() {}

  public static let `default` = PanelStyle()

  /// The margin the chrome keeps from the container's edges on `mode`.
  func edgeMargin(for mode: LayoutMode) -> CGFloat {
    mode == .bottomSheet ? edgeMarginCompact : edgeMarginRegular
  }
}
