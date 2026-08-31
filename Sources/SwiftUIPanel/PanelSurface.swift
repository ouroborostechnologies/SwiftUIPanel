import SwiftUI

/// The material, radius, and shadow every floating surface wears, so the panel
/// and the toast read as siblings rather than two visual languages.
private struct PanelSurface: ViewModifier {

  let style: PanelStyle
  let cornerRadius: CGFloat

  func body(content: Content) -> some View {
    content
      .background(style.material, in: shape)
      .clipShape(shape)
      .shadow(color: .black.opacity(style.shadowOpacity), radius: style.shadowRadius, y: style.shadowYOffset)
  }

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
  }
}

extension View {

  /// Draws this content as a floating surface. `cornerRadius: nil` uses the
  /// style's own.
  func panelSurface(_ style: PanelStyle, cornerRadius: CGFloat? = nil) -> some View {
    modifier(PanelSurface(style: style, cornerRadius: cornerRadius ?? style.cornerRadius))
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
