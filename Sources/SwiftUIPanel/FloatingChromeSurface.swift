import SwiftUI

extension RectangleCornerRadii {
  /// The same radius on every corner.
  static func all(_ radius: CGFloat) -> RectangleCornerRadii {
    RectangleCornerRadii(topLeading: radius, bottomLeading: radius, bottomTrailing: radius, topTrailing: radius)
  }
}

/// The one background every floating surface uses.
struct FloatingChromeSurface: ViewModifier {

  let style: PanelStyle
  let radii: RectangleCornerRadii

  func body(content: Content) -> some View {
    content
      .background(style.material, in: shape)
      .clipShape(shape)
      .shadow(color: .black.opacity(style.shadowOpacity), radius: style.shadowRadius, y: style.shadowYOffset)
  }

  private var shape: UnevenRoundedRectangle {
    UnevenRoundedRectangle(cornerRadii: radii, style: .continuous)
  }
}

extension View {
  /// `radii: nil` uses the style's own radius on every corner.
  func floatingChrome(_ style: PanelStyle, radii: RectangleCornerRadii? = nil) -> some View {
    modifier(FloatingChromeSurface(style: style, radii: radii ?? .all(style.cornerRadius)))
  }
}

extension View {
  /// A keyboard focus section on the Mac; iOS has no equivalent at this
  /// deployment target and its focus engine orders the panel on its own.
  @ViewBuilder
  func keyboardFocusSection() -> some View {
    #if os(macOS)
    focusSection()
    #else
    self
    #endif
  }
}
