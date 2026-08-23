import SwiftUI

/// iPad and Mac: an inspector anchored top-left, resized from its bottom edge.
/// It floats over the content; it never pushes it.
struct FloatingCornerPanel<Content: View>: View {

  let style: FloatingChromeStyle
  let width: CGFloat
  let height: CGFloat
  let tabs: [FloatingPanelTab]
  @Binding var selection: FloatingPanelTab.ID
  let content: (FloatingPanelTab.ID) -> Content
  let onResize: (_ translation: CGFloat, _ ended: Bool) -> Void

  static var resizeHandleHeight: CGFloat { 14 }

  var body: some View {
    VStack(spacing: 0) {
      content(selection)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      Divider()
      FloatingPanelTabBar(tabs: tabs, selection: $selection)
      resizeHandle
    }
    .frame(width: width, height: height)
    .floatingChrome(style, corners: .all)
  }

  private var resizeHandle: some View {
    Capsule()
      .fill(.tertiary)
      .frame(width: 36, height: 4)
      .frame(maxWidth: .infinity)
      .frame(height: Self.resizeHandleHeight)
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
          .onChanged { onResize($0.translation.height, false) }
          .onEnded { onResize($0.translation.height, true) }
      )
      #if os(macOS)
      .onHover { hovering in
        if hovering { NSCursor.resizeUpDown.push() } else { NSCursor.pop() }
      }
      #endif
      .accessibilityLabel("Resize panel")
  }
}
