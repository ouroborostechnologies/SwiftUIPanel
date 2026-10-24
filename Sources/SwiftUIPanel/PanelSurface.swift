import SwiftUI

/// The glass and radius every floating surface wears, so the panel and the
/// toast read as siblings rather than two visual languages.
///
/// Liquid Glass draws its own shading, edge highlight, and shadow, so there is
/// nothing left here to layer on top of it.
private struct PanelSurface: ViewModifier {

  let style: PanelStyle
  let cornerRadii: RectangleCornerRadii
  /// Read outside the glass, so `.system` re-asserts the appearance the app is
  /// actually running in rather than the one the glass resolved for itself.
  @Environment(\.colorScheme) private var environmentScheme

  func body(content: Content) -> some View {
    content
      .glassEffect(style.glass, in: shape)
      .clipShape(shape)
      .panelColorScheme(style.glassScheme, environment: environmentScheme)
  }

  private var shape: UnevenRoundedRectangle {
    UnevenRoundedRectangle(cornerRadii: cornerRadii, style: .continuous)
  }
}

extension View {

  /// Draws this content as a floating surface. `cornerRadii: nil` draws the
  /// style's own radius on all four corners.
  func panelSurface(_ style: PanelStyle, cornerRadii: RectangleCornerRadii? = nil) -> some View {
    modifier(PanelSurface(style: style,
                          cornerRadii: cornerRadii ?? RectangleCornerRadii(style.cornerRadius)))
  }

  /// Pins the appearance a glass surface and its content render in.
  ///
  /// - Parameter environment: the scheme in force outside the glass, which
  ///   `.system` re-asserts inside it.
  @ViewBuilder
  func panelColorScheme(_ scheme: PanelGlassScheme, environment: ColorScheme) -> some View {
    switch scheme {
    case .adaptive:
      self
    case .system:
      self.environment(\.colorScheme, environment)
    case let .fixed(scheme):
      self.environment(\.colorScheme, scheme)
    }
  }

  /// Groups the panel's controls for keyboard focus on the Mac. iOS orders
  /// them on its own.
  @ViewBuilder
  func keyboardFocusSection() -> some View {
    #if os(macOS)
    focusSection()
    #else
    self
    #endif
  }
}

extension View {

  /// Draws this content on the buttons' glass, in the appearance the style's
  /// `glassScheme` asks for.
  ///
  /// Small glass flips light or dark by what is behind it, whatever
  /// appearance it is given, and recolours the label colours drawn on it to
  /// match — so a button over satellite imagery turns dark in light mode. Under
  /// a pinned scheme the content is drawn in concrete colours the glass leaves
  /// alone instead: a wash of the appearance's own background, and its label
  /// colour on top. The glass still refracts and responds at the edges, but the
  /// control reads the same over any map. `.adaptive` leaves the glass to it.
  ///
  /// A label that sets its own foreground keeps it; one that does not takes
  /// the scheme's.
  public func panelControlGlass(_ style: PanelStyle, in shape: some Shape) -> some View {
    modifier(PanelControlGlass(style: style, shape: shape))
  }
}

private struct PanelControlGlass<S: Shape>: ViewModifier {

  let style: PanelStyle
  let shape: S

  /// See `PanelSurface`: read outside the glass.
  @Environment(\.colorScheme) private var environmentScheme
  @Environment(\.isEnabled) private var isEnabled

  func body(content: Content) -> some View {
    if let scheme = style.glassScheme.pinnedScheme(environment: environmentScheme) {
      let label = scheme == .dark ? Color.white : Color.black
      content
        // Concrete, not `.primary`: a hierarchical style is the glass's to recolour.
        .foregroundStyle(label.opacity(isEnabled ? 1 : 0.3))
        .background {
          shape.fill(scheme == .dark
                     ? Color.black.opacity(style.controlGlassWashDark)
                     : Color.white.opacity(style.controlGlassWashLight))
        }
        .glassEffect(style.buttonGlass.interactive(), in: shape)
        .environment(\.colorScheme, scheme)
    } else {
      content
        .glassEffect(style.buttonGlass.interactive(), in: shape)
    }
  }
}

extension PanelGlassScheme {

  /// The appearance this pins the chrome to, or nil when the glass decides.
  func pinnedScheme(environment: ColorScheme) -> ColorScheme? {
    switch self {
    case .adaptive: nil
    case .system: environment
    case let .fixed(scheme): scheme
    }
  }
}
