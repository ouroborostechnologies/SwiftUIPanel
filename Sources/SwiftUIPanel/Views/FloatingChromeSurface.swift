import SwiftUI

/// Which corners a surface rounds.
enum ChromeCorners {
  case all
  case top
}

/// The one background every floating surface uses.
struct FloatingChromeSurface: ViewModifier {

  let style: FloatingChromeStyle
  let corners: ChromeCorners

  func body(content: Content) -> some View {
    content
      .background(style.material, in: shape)
      .clipShape(shape)
      .shadow(color: .black.opacity(style.shadowOpacity), radius: style.shadowRadius, y: style.shadowYOffset)
  }

  private var shape: UnevenRoundedRectangle {
    let r = style.cornerRadius
    switch corners {
    case .all:
      return UnevenRoundedRectangle(topLeadingRadius: r, bottomLeadingRadius: r,
                                    bottomTrailingRadius: r, topTrailingRadius: r, style: .continuous)
    case .top:
      return UnevenRoundedRectangle(topLeadingRadius: r, bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 0, topTrailingRadius: r, style: .continuous)
    }
  }
}

extension View {
  func floatingChrome(_ style: FloatingChromeStyle, corners: ChromeCorners = .all) -> some View {
    modifier(FloatingChromeSurface(style: style, corners: corners))
  }
}
