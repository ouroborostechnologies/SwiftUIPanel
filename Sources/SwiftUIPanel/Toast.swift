import SwiftUI

/// The transient surface at the top of the container: content in the panel's
/// chrome, no shorter than a comfortable target.
struct Toast<Content: View>: View {

  let style: PanelStyle
  @ViewBuilder let content: Content

  var body: some View {
    content
      .padding(.horizontal, style.surfacePaddingHorizontal)
      .padding(.vertical, style.surfacePaddingVertical)
      .frame(minHeight: style.minimumTouchHeight)
      .panelSurface(style)
  }
}
