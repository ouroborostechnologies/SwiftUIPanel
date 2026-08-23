import SwiftUI

/// iPad and Mac: an inspector anchored top-left, resized from its trailing
/// edge, its bottom edge, or the corner between them. It floats over the
/// content; it never pushes it.
struct FloatingCornerPanel<Content: View>: View {

  let style: FloatingChromeStyle
  let size: CGSize
  let tabs: [FloatingPanelTab]
  @Binding var selection: FloatingPanelTab.ID
  let content: (FloatingPanelTab.ID) -> Content
  let onResize: (_ edge: ResizeEdge, _ translation: CGSize, _ ended: Bool) -> Void

  static var gripThickness: CGFloat { 14 }

  var body: some View {
    VStack(spacing: 0) {
      content(selection)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      Divider()
      FloatingPanelTabBar(tabs: tabs, selection: $selection)
        .padding(.bottom, Self.gripThickness - 4)
    }
    .frame(width: size.width, height: size.height)
    .floatingChrome(style, corners: .all)
    .overlay(alignment: .trailing) { grip(.trailing) }
    .overlay(alignment: .bottom) { grip(.bottom) }
    .overlay(alignment: .bottomTrailing) { grip(.bottomTrailing) }
  }

  /// A capsule on the edge, with a wider invisible hit area, a drag gesture,
  /// and a pointer cue.
  private func grip(_ edge: ResizeEdge) -> some View {
    Group {
      switch edge {
      case .trailing:
        Capsule().fill(.tertiary).frame(width: 4, height: 36)
          .frame(width: Self.gripThickness, height: size.height - Self.gripThickness * 2)
      case .bottom:
        Capsule().fill(.tertiary).frame(width: 36, height: 4)
          .frame(width: size.width - Self.gripThickness * 2, height: Self.gripThickness)
      case .bottomTrailing:
        Image(systemName: "arrow.up.left.and.arrow.down.right")
          .font(.system(size: 8, weight: .bold))
          .foregroundStyle(.tertiary)
          .frame(width: Self.gripThickness + 4, height: Self.gripThickness + 4)
      }
    }
    .contentShape(Rectangle())
    .resizeCursor(edge)
    .gesture(
      DragGesture(minimumDistance: 1, coordinateSpace: .global)
        .onChanged { onResize(edge, $0.translation, false) }
        .onEnded { onResize(edge, $0.translation, true) }
    )
    .accessibilityLabel("Resize panel")
  }
}
