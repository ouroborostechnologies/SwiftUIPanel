import SwiftUI

/// Every number and material the chrome draws with.
///
/// This is the one place in the package where a point value is written down;
/// layout code reads these names. Set the properties you want to change on a
/// fresh instance and assign it to `PanelController.style`.
///
/// ```swift
/// panel.style.glass = .clear
/// panel.style.panelWidth = 380
/// ```
public struct PanelStyle: Sendable {

  // MARK: Surfaces

  /// The Liquid Glass the panel and the toast are drawn on. Glass carries its
  /// own shading and shadow, so neither surface draws one of its own.
  public var glass: Glass = .regular
  /// The buttons' glass. `interactive()` is applied by the button style, which
  /// is the only place that knows whether a button is being pressed.
  public var buttonGlass: Glass = .regular
  /// What decides the appearance every glass surface renders in, content
  /// included.
  public var glassScheme: PanelGlassScheme = .adaptive
  /// Panel and toast corners, and the floor under a concentric radius. Drawn
  /// on all four corners of a surface unless something below reshapes them.
  public var cornerRadius: CGFloat = 16
  /// What a bottom sheet's top corners take of the radius its bottom corners
  /// resolved to, on iOS. The sheet's bottom meets the display's own curve
  /// while its top edge stands away from it, and a flatter top reads better
  /// there — the same relationship the system's own sheets draw. `1` draws all
  /// four corners alike.
  public var sheetTopCornerScale: CGFloat = 0.7
  /// A control that is pressed, or showing an off state.
  public var dimmedOpacity: Double = 0.6

  // MARK: Spacing

  /// The chrome's distance from the container's edges on narrow layouts. Where
  /// the safe area asks for more, the safe area wins.
  public var edgeMarginCompact: CGFloat = 8
  /// The same, on wide layouts.
  public var edgeMarginRegular: CGFloat = 12
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

  /// The panel's four corners on `mode`, given the uniform `radius` its
  /// concentric fit resolved to.
  ///
  /// Two conditions have to hold for the top corners to be drawn tighter than
  /// the bottom: the platform is iOS, and the width resolved to a sheet.
  /// Anything else — a Mac window, an iPad wide enough for the corner panel —
  /// keeps its four corners alike.
  func panelCornerRadii(_ radius: CGFloat, mode: LayoutMode) -> RectangleCornerRadii {
    #if os(iOS)
    guard mode == .bottomSheet else { return RectangleCornerRadii(radius) }
    let top = radius * min(max(sheetTopCornerScale, 0), 1)
    return RectangleCornerRadii(topLeading: top, bottomLeading: radius,
                                bottomTrailing: radius, topTrailing: top)
    #else
    return RectangleCornerRadii(radius)
    #endif
  }
}

public extension RectangleCornerRadii {

  /// The same radius on all four corners.
  init(_ radius: CGFloat) {
    self.init(topLeading: radius, bottomLeading: radius,
              bottomTrailing: radius, topTrailing: radius)
  }
}

/// Where a glass surface takes its light or dark appearance from.
///
/// Liquid Glass lightens and darkens with whatever passes behind it, which
/// over a map or a video means chrome that changes colour as the content moves
/// under it. The other two cases take that decision away from the backdrop.
public enum PanelGlassScheme: Sendable, Equatable {

  /// Liquid Glass's own behaviour: light or dark by what is behind the
  /// surface. The default, and what a surface over ordinary content wants.
  case adaptive
  /// Whatever the system appearance is set to, backdrop ignored — so the
  /// chrome follows the user's light or dark setting and nothing else.
  case system
  /// One appearance, whatever the system and the backdrop are doing.
  case fixed(ColorScheme)
}
