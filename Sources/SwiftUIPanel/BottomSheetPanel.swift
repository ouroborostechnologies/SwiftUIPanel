import SwiftUI

/// iPhone: a card floating above the bottom edge, inset from the display on
/// every side until it goes edge-to-edge at `.full`, dragged from its handle
/// or the top strip of its content, and snapping between detents by projected
/// velocity. Corners are concentric with the display's own.
struct BottomSheetPanel<Content: View>: View {

  let style: PanelStyle
  let tabs: [FloatingPanelTab]
  @Binding var selection: FloatingPanelTab.ID
  let displayedHeight: CGFloat
  /// Concentric with the display for the sheet's current inset.
  let cornerRadius: CGFloat
  /// The part of the bottom safe area the sheet currently extends into — it
  /// floats one margin (not a whole safe area) above the display's bottom
  /// edge; its content stays clear of the home indicator via this inset.
  let bottomSafeInset: CGFloat
  let isDraggable: Bool
  let content: (FloatingPanelTab.ID) -> Content
  /// The measured chrome — handle, tab bar, bottom inset. Fully collapsed,
  /// the sheet is exactly this tall: the tab bar and nothing else.
  let onChromeHeightChange: (CGFloat) -> Void
  /// Any tab press; a collapsed sheet opens on it.
  let onTabTapped: () -> Void
  let onDragChanged: (CGFloat) -> Void
  let onDragEnded: (_ predictedTranslation: CGFloat) -> Void

  @State private var handleHeight: CGFloat = 0
  @State private var barHeight: CGFloat = 0

  /// Dragging is recognised on the handle and this much of the content's top.
  static var topDragStrip: CGFloat { 24 }

  var body: some View {
    VStack(spacing: 0) {
      handle
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { handleHeight = $0 }
      PanelTabs(tabs: tabs, selection: $selection,
                bottomInset: bottomSafeInset,
                onBarHeightChange: { barHeight = $0 },
                onTabTap: onTabTapped,
                content: content)
        .overlay(alignment: .top) { topDragZone }
    }
    .frame(maxWidth: .infinity)
    .frame(height: max(displayedHeight, 0), alignment: .top)
    .floatingChrome(style, radii: .all(cornerRadius))
    .keyboardFocusSection()
    .onChange(of: handleHeight + barHeight, initial: true) { _, chrome in
      onChromeHeightChange(chrome)
    }
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
