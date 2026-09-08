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
  /// Whether the sheet is resting at its tallest detent, the one state in
  /// which a scroll view in the main slot hands its downward drag over.
  let isFullyOpen: Bool
  @ViewBuilder let main: Main
  @ViewBuilder let bar: Bar
  /// Reports the height of `.minimized`: the handle, the bar, and the inset.
  let onBarHeightChange: (CGFloat) -> Void
  let onDragChanged: (CGFloat) -> Void
  let onDragEnded: (_ projectedTranslation: CGFloat) -> Void

  @State private var handleHeight: CGFloat = 0
  @State private var barHeight: CGFloat = 0
  /// The main slot's scroll view, if it has one, and whether it is at its top.
  @State private var mainScroll = MainScrollState()
  /// Whether the drag that started in the scroll view has taken the sheet
  /// over. Latched, so a drag that begins at the top keeps moving the sheet
  /// after the scroll view has bounced away from it.
  @State private var scrollHandoff = false

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
          .onScrollGeometryChange(for: MainScrollState.self) {
            MainScrollState(exists: $0.containerSize.height > 0,
                            isAtTop: $0.contentOffset.y <= -$0.contentInsets.top + 0.5)
          } action: { _, state in mainScroll = state }
          // The system's own sheets let a scroll view at its top drag the
          // sheet down instead of bouncing. `simultaneousGesture` is how that
          // is expressed here: the scroll view keeps its gesture, and this one
          // recognises alongside it rather than replacing anything.
          .simultaneousGesture(scrollHandoffGesture, isEnabled: handsOffScrollDrags)
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

  /// Whether a downward drag inside the main slot's scroll view should move
  /// the sheet: on iOS, at the tallest detent, with a scroll view there to
  /// hand the drag over. On the Mac a sheet is dragged by its handle.
  private var handsOffScrollDrags: Bool {
    #if os(iOS)
    isFullyOpen && mainScroll.exists
    #else
    false
    #endif
  }

  /// The sheet's drag, taken over from a scroll view sitting at its top.
  ///
  /// It stays out of the way until the scroll view has nowhere left to go:
  /// the handoff latches only while the content is at the top and the finger
  /// is moving down, so scrolling up, and every drag from further down the
  /// content, still belongs to the scroll view.
  private var scrollHandoffGesture: some Gesture {
    DragGesture(minimumDistance: style.dragMinimumDistance, coordinateSpace: .global)
      .onChanged { value in
        if !scrollHandoff {
          guard mainScroll.isAtTop, value.translation.height > 0 else { return }
          scrollHandoff = true
        }
        onDragChanged(value.translation.height)
      }
      .onEnded { value in
        guard scrollHandoff else { return }
        scrollHandoff = false
        onDragEnded(value.predictedEndTranslation.height)
      }
  }

  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: style.dragMinimumDistance, coordinateSpace: .global)
      .onChanged { onDragChanged($0.translation.height) }
      .onEnded { onDragEnded($0.predictedEndTranslation.height) }
  }
}

/// What the main slot's scroll view, if it has one, last reported.
private struct MainScrollState: Equatable {
  /// False until a scroll view in the slot lays out, so content without one
  /// never has a drag taken off it.
  var exists = false
  var isAtTop = true
}
