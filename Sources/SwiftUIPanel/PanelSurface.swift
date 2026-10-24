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
