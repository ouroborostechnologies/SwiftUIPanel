import SwiftUI

/// The narrow layout: a card floating above the container's bottom edge,
/// dragged from its handle or the top strip of its content.
///
/// It knows nothing about what is in either slot — only that the bar is pinned
/// to its bottom edge and the main slot fills what is left.
struct BottomSheetPanel<Main: View, Bar: View>: View {

  let style: PanelStyle
  let height: CGFloat
  let cornerRadii: RectangleCornerRadii
  /// Padding under the bar slot, keeping its content clear of the home
  /// indicator the sheet floats over.
  let barBottomInset: CGFloat
  @ViewBuilder let main: Main
  @ViewBuilder let bar: Bar
  /// Reports the height of `.minimized`: the handle, the bar, and the inset.
  let onBarHeightChange: (CGFloat) -> Void
  let onDragChanged: (CGFloat) -> Void
  let onDragEnded: (_ projectedTranslation: CGFloat) -> Void

  @State private var handleHeight: CGFloat = 0
  @State private var barHeight: CGFloat = 0

  var body: some View {
    VStack(spacing: 0) {
      handle
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { handleHeight = $0 }
      VStack(spacing: 0) {
        // A zero minimum lets the slot collapse below its content's own, and
        // clipping stops a shrinking sheet showing a sliver spilling past the bar.
        main
          .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
          .clipped()
        bar
          .padding(.bottom, barBottomInset)
          .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { barHeight = $0 }
      }
      .overlay(alignment: .top) { contentDragStrip }
    }
    .frame(maxWidth: .infinity)
    .frame(height: max(height, 0), alignment: .top)
    .panelSurface(style, cornerRadii: cornerRadii)
    .keyboardFocusSection()
    .onChange(of: handleHeight + barHeight, initial: true) { _, minimizedHeight in
      onBarHeightChange(minimizedHeight)
    }
  }

  private var handle: some View {
    Capsule()
      .fill(.tertiary)
      .frame(width: style.dragHandleWidth, height: style.dragHandleHeight)
      .padding(.vertical, style.surfacePaddingVertical)
      .frame(maxWidth: .infinity)
      .contentShape(Rectangle())
      .gesture(dragGesture)
      .accessibilityLabel("Resize panel")
  }

  /// Invisible, so a drag can also start from the content's top edge.
  private var contentDragStrip: some View {
    Color.clear
      .frame(height: style.dragStripHeight)
      .contentShape(Rectangle())
      .gesture(dragGesture)
  }

  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: style.dragMinimumDistance, coordinateSpace: .global)
      .onChanged { onDragChanged($0.translation.height) }
      .onEnded { onDragEnded($0.predictedEndTranslation.height) }
  }
}
