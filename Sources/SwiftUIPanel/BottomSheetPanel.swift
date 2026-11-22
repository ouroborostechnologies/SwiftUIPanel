import SwiftUI

/// The narrow layout: a card floating above the container's bottom edge,
/// dragged from its handle or the top strip of its content.
///
/// It knows nothing about what is in either slot — only that the bar is pinned
/// to its bottom edge and the main slot fills what is left. Focused, it is the
/// main slot alone, at its content's height, with nothing to drag.
struct BottomSheetPanel<Main: View, Bar: View>: View {

  let style: PanelStyle
  let height: CGFloat
  let cornerRadii: RectangleCornerRadii
  /// Padding under the bar slot, keeping its content clear of the home
  /// indicator the sheet floats over. Under the main slot when focused, unless
  /// `PanelStyle.focusedBottomInset` replaces it.
  let barBottomInset: CGFloat
  let isFocused: Bool
  /// The tallest the sheet may fit itself to when focused.
  let maxHeight: CGFloat
  @ViewBuilder let main: Main
  @ViewBuilder let bar: Bar
  /// Reports the height of `.minimized`: the handle, the bar, and the inset.
  let onBarHeightChange: (CGFloat) -> Void
  /// Reports, while focused, the height the main slot's content asks for.
  let onFittedHeightChange: (CGFloat) -> Void
  let onDragChanged: (CGFloat) -> Void
  let onDragEnded: (_ projectedTranslation: CGFloat) -> Void

  @State private var handleHeight: CGFloat = 0
  @State private var barHeight: CGFloat = 0

  var body: some View {
    VStack(spacing: 0) {
      if !isFocused {
        handle
          .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { handleHeight = $0 }
      }
      VStack(spacing: 0) {
        MainSlot(fittingHeight: isFocused ? max(maxHeight - focusedBottomInset, 0) : nil) { main }
          .padding(.bottom, isFocused ? focusedBottomInset : 0)
          .background { if isFocused { FittedHeightProbe(onChange: onFittedHeightChange) } }
        if !isFocused {
          bar
            .padding(.bottom, barBottomInset)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { barHeight = $0 }
        }
      }
      .overlay(alignment: .top) {
        if !isFocused { contentDragStrip }
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: max(height, 0), alignment: .top)
    .panelSurface(style, cornerRadii: cornerRadii)
    .keyboardFocusSection()
    .onChange(of: handleHeight + barHeight, initial: true) { _, minimizedHeight in
      onBarHeightChange(minimizedHeight)
    }
  }

  /// Under the main slot while focused: the bar's inset, unless the style says otherwise.
  private var focusedBottomInset: CGFloat {
    style.focusedBottomInset ?? barBottomInset
  }

  private var handle: some View {
    Capsule()
      .fill(.secondary)
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
