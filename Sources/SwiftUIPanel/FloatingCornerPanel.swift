import SwiftUI

/// The wide layout: a panel anchored top-leading, resized from its trailing
/// edge, its bottom edge, or the corner between them.
///
/// The grips draw nothing — the pointer changing is the affordance — and are
/// only as thick as a comfortable target. Focused, it is the main slot alone,
/// at its content's height, and only its width can be dragged.
struct FloatingCornerPanel<Main: View, Bar: View>: View {

  let style: PanelStyle
  let size: CGSize
  let cornerRadii: RectangleCornerRadii
  let isFocused: Bool
  /// The tallest the panel may fit itself to when focused.
  let maxHeight: CGFloat
  @ViewBuilder let main: Main
  @ViewBuilder let bar: Bar
  /// Reports, while focused, the height the main slot's content asks for.
  let onFittedHeightChange: (CGFloat) -> Void
  /// `projectedTranslation` is non-nil only on the drag that ends the resize.
  let onResize: (ResizeEdge, _ translation: CGSize, _ projectedTranslation: CGSize?) -> Void

  var body: some View {
    VStack(spacing: 0) {
      MainSlot(fittingHeight: isFocused ? maxHeight : nil) { main }
        .background { if isFocused { FittedHeightProbe(onChange: onFittedHeightChange) } }
      if !isFocused {
        bar
      }
    }
    .frame(width: size.width, height: size.height, alignment: .top)
    .panelSurface(style, cornerRadii: cornerRadii)
    .overlay(alignment: .trailing) { grip(.trailing) }
    .overlay(alignment: .bottom) {
      if !isFocused { grip(.bottom) }
    }
    .overlay(alignment: .bottomTrailing) {
      if !isFocused { grip(.bottomTrailing) }
    }
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
