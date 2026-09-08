import SwiftUI

/// The wide layout: a panel anchored top-leading, resized from its trailing
/// edge, its bottom edge, or the corner between them.
///
/// The grips draw nothing — the pointer changing is the affordance — and are
/// only as thick as a comfortable target.
struct FloatingCornerPanel<Main: View, Bar: View>: View {

  let style: PanelStyle
  let size: CGSize
  let cornerRadii: RectangleCornerRadii
  @ViewBuilder let main: Main
  @ViewBuilder let bar: Bar
  /// `projectedTranslation` is non-nil only on the drag that ends the resize.
  let onResize: (ResizeEdge, _ translation: CGSize, _ projectedTranslation: CGSize?) -> Void

  var body: some View {
    VStack(spacing: 0) {
      main
        .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .clipped()
      bar
    }
    .frame(width: size.width, height: size.height)
    .panelSurface(style, cornerRadii: cornerRadii)
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
        DragGesture(minimumDistance: style.dragMinimumDistance, coordinateSpace: .global)
          .onChanged { onResize(edge, $0.translation, nil) }
          .onEnded { onResize(edge, $0.translation, $0.predictedEndTranslation) }
      )
      .accessibilityLabel("Resize panel")
  }

  /// Each grip spans its own edge, stopping short of the corner so the three
  /// targets never overlap.
  private func gripSize(_ edge: ResizeEdge) -> CGSize {
    let thickness = style.gripThickness
    switch edge {
    case .trailing: return CGSize(width: thickness, height: max(size.height - thickness * 2, 0))
    case .bottom: return CGSize(width: max(size.width - thickness * 2, 0), height: thickness)
    case .bottomTrailing: return CGSize(width: thickness * 2, height: thickness * 2)
    }
  }
}
