import SwiftUI

/// iPad and Mac: an inspector anchored top-left, resized from its trailing
/// edge, its bottom edge, or the corner between them. It floats over the
/// content; it never pushes it.
///
/// The grips draw nothing — the pointer changing is the affordance — and are
/// only as thick as a comfortable target.
struct FloatingCornerPanel<Content: View>: View {

  let style: FloatingChromeStyle
  let size: CGSize
  let tabs: [FloatingPanelTab]
  @Binding var selection: FloatingPanelTab.ID
  let content: (FloatingPanelTab.ID) -> Content
  /// `predictedTranslation` is non-nil only when the drag ends.
  let onResize: (_ edge: ResizeEdge, _ translation: CGSize, _ predictedTranslation: CGSize?) -> Void

  static var gripThickness: CGFloat { 10 }

  var body: some View {
    PanelTabs(tabs: tabs, selection: $selection, content: content)
      .padding(.bottom, 4)
      .frame(width: size.width, height: size.height)
      .floatingChrome(style, corners: .all)
      .overlay(alignment: .trailing) { grip(.trailing) }
      .overlay(alignment: .bottom) { grip(.bottom) }
      .overlay(alignment: .bottomTrailing) { grip(.bottomTrailing) }
      .keyboardFocusSection()
  }

  private func grip(_ edge: ResizeEdge) -> some View {
    Color.clear
      .frame(width: gripSize(edge).width, height: gripSize(edge).height)
      .contentShape(Rectangle())
      .resizeCursor(edge)
      .gesture(
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
          .onChanged { onResize(edge, $0.translation, nil) }
          .onEnded { onResize(edge, $0.translation, $0.predictedEndTranslation) }
      )
      .accessibilityLabel("Resize panel")
  }

  private func gripSize(_ edge: ResizeEdge) -> CGSize {
    let t = Self.gripThickness
    switch edge {
    case .trailing: return CGSize(width: t, height: max(size.height - t * 2, 0))
    case .bottom: return CGSize(width: max(size.width - t * 2, 0), height: t)
    case .bottomTrailing: return CGSize(width: t * 2, height: t * 2)
    }
  }
}
