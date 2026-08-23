import SwiftUI

/// iPhone: a card floating above the bottom edge, inset from the display on
/// every side, dragged from its handle or the top strip of its content, and
/// snapping between detents by projected velocity.
struct BottomSheetPanel<Content: View>: View {

  let style: FloatingChromeStyle
  let tabs: [FloatingPanelTab]
  @Binding var selection: FloatingPanelTab.ID
  let displayedHeight: CGFloat
  let isDraggable: Bool
  let content: (FloatingPanelTab.ID) -> Content
  let onDragChanged: (CGFloat) -> Void
  let onDragEnded: (_ predictedTranslation: CGFloat) -> Void

  /// Dragging is recognised on the handle and this much of the content's top.
  static var topDragStrip: CGFloat { 24 }

  var body: some View {
    VStack(spacing: 0) {
      handle
      PanelTabs(tabs: tabs, selection: $selection, content: content)
        .overlay(alignment: .top) { topDragZone }
    }
    .frame(maxWidth: .infinity)
    .frame(height: max(displayedHeight, 0))
    .floatingChrome(style, corners: .all)
    .keyboardFocusSection()
  }

  private var handle: some View {
    Capsule()
      .fill(.tertiary)
      .frame(width: 36, height: 5)
      .padding(.vertical, 8)
      .frame(maxWidth: .infinity)
      .contentShape(Rectangle())
      .gesture(dragGesture)
      .accessibilityLabel("Resize panel")
  }

  /// Invisible; lets a drag start from the content's top edge.
  private var topDragZone: some View {
    Color.clear
      .frame(height: Self.topDragStrip)
      .contentShape(Rectangle())
      .gesture(dragGesture)
  }

  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: 2, coordinateSpace: .global)
      .onChanged { value in
        guard isDraggable else { return }
        onDragChanged(value.translation.height)
      }
      .onEnded { value in
        guard isDraggable else { return }
        onDragEnded(value.predictedEndTranslation.height)
      }
  }
}
