import SwiftUI

public extension View {

  /// Overlays a Maps-style floating panel, tab bar, map buttons, and optional
  /// taskbar on this full-bleed content, and publishes what they cover via
  /// `\.floatingPanelInsets` (and `FloatingPanelGeometryKey` for raw frames).
  ///
  /// Attach it to the map itself — the view that already ignores the safe
  /// area. The chrome stays inside the safe area on its own.
  ///
  /// - Parameters:
  ///   - taskbar: `nil` hides the taskbar. On iPhone its presence forces the
  ///     sheet to its smallest detent.
  func floatingPanel<Content: View>(
    configuration: FloatingPanelConfiguration = .default,
    tabs: [FloatingPanelTab],
    selection: Binding<FloatingPanelTab.ID>,
    isPanelVisible: Binding<Bool> = .constant(true),
    actions: FloatingPanelActions = FloatingPanelActions(),
    taskbar: TemporaryTaskbarContent? = nil,
    @ViewBuilder content: @escaping (FloatingPanelTab.ID) -> Content
  ) -> some View {
    modifier(FloatingPanelModifier(configuration: configuration,
                                   tabs: tabs,
                                   selection: selection,
                                   isPanelVisible: isPanelVisible,
                                   actions: actions,
                                   taskbar: taskbar,
                                   panelContent: content))
  }
}

/// The whole shell. One `GeometryReader`, one pass per state change that
/// yields the sheet height, the corner height, the insets, and the frames —
/// so the content underneath and the chrome on top can never disagree.
struct FloatingPanelModifier<PanelContent: View>: ViewModifier {

  let configuration: FloatingPanelConfiguration
  let tabs: [FloatingPanelTab]
  @Binding var selection: FloatingPanelTab.ID
  @Binding var isPanelVisible: Bool
  let actions: FloatingPanelActions
  let taskbar: TemporaryTaskbarContent?
  let panelContent: (FloatingPanelTab.ID) -> PanelContent

  /// The sheet's detent between drags.
  @State private var restingDetent: FloatingPanelDetent?
  /// The live drag, positive downwards. Reset by SwiftUI when the gesture ends.
  @State private var sheetDrag: CGFloat = 0
  @State private var cornerHeight: CGFloat?
  @State private var cornerResizeStart: CGFloat?
  @State private var taskbarHeight: CGFloat = 0

  static var taskbarGap: CGFloat { 8 }

  private var style: FloatingChromeStyle { configuration.style }

  func body(content: Content) -> some View {
    GeometryReader { geometry in
      let mode = PlatformIdiom.resolve(override: configuration.layoutModeOverride)
      let safe = geometry.safeAreaInsets
      let full = CGSize(width: geometry.size.width + safe.leading + safe.trailing,
                        height: geometry.size.height + safe.top + safe.bottom)
      let margin = style.edgeMargin(for: mode)

      switch mode {
      case .bottomSheet:
        bottomSheetLayout(content: content, full: full, safe: safe, margin: margin)
      case .floatingCorner:
        floatingCornerLayout(content: content, full: full, safe: safe, margin: margin)
      }
    }
  }

  // MARK: - iPhone

  @ViewBuilder
  private func bottomSheetLayout(content: Content, full: CGSize, safe: EdgeInsets, margin: CGFloat) -> some View {
    let layout = SheetLayout(containerHeight: full.height, detents: configuration.detents)
    let resting = restingDetent ?? (layout.contains(configuration.initialDetent) ? configuration.initialDetent : layout.smallest)
    // One derived state: a taskbar forces the smallest detent and suspends
    // dragging, so the two surfaces never animate against each other.
    let effective = taskbar == nil ? resting : layout.smallest
    let sheetHeight = isPanelVisible ? layout.displayedHeight(resting: effective, dragTranslation: taskbar == nil ? sheetDrag : 0) : 0
    let insets = PanelInsets.bottomSheet(sheetHeight: sheetHeight,
                                         taskbarHeight: taskbar == nil ? nil : taskbarHeight,
                                         gap: Self.taskbarGap)
    let sheetFrame = CGRect(x: 0, y: full.height - sheetHeight, width: full.width, height: sheetHeight)

    content
      .environment(\.floatingPanelInsets, insets)
      .preference(key: FloatingPanelGeometryKey.self, value: isPanelVisible ? sheetFrame : .zero)
      .overlay(alignment: .topTrailing) {
        if configuration.showsMapOverlayButtons {
          buttonStack
            .padding(.top, safe.top + margin)
            .padding(.trailing, safe.trailing + margin)
        }
      }
      .overlay(alignment: .bottom) {
        VStack(spacing: Self.taskbarGap) {
          if let taskbar {
            TemporaryTaskbar(style: style, taskbar: taskbar)
              .padding(.horizontal, margin)
              .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { taskbarHeight = $0 }
              .transition(.move(edge: .bottom).combined(with: .opacity))
          }
          if isPanelVisible {
            BottomSheetPanel(style: style,
                             layout: layout,
                             tabs: tabs,
                             selection: $selection,
                             displayedHeight: sheetHeight,
                             isDraggable: taskbar == nil,
                             safeAreaBottom: safe.bottom,
                             content: panelContent,
                             onDragChanged: { sheetDrag = $0 },
                             onDragEnded: { predicted in
                               let next = layout.snappedDetent(resting: resting, predictedTranslation: predicted)
                               withAnimation(style.animation) {
                                 restingDetent = next
                                 sheetDrag = 0
                               }
                             })
              .transition(.move(edge: .bottom))
          }
        }
        .animation(style.animation, value: taskbar?.id)
        .animation(style.animation, value: isPanelVisible)
      }
  }

  // MARK: - iPad and Mac

  @ViewBuilder
  private func floatingCornerLayout(content: Content, full: CGSize, safe: EdgeInsets, margin: CGFloat) -> some View {
    let available = full.height - safe.top - safe.bottom - margin * 2
    let layout = CornerLayout(configuredRange: configuration.cornerPanelHeightRange, availableHeight: available)
    let height = layout.clamped(cornerHeight ?? configuration.initialCornerPanelHeight)
    let width = configuration.cornerPanelWidth
    let insets = isPanelVisible
      ? PanelInsets.floatingCorner(safeLeading: safe.leading, margin: margin, width: width)
      : EdgeInsets()
    let panelFrame = CGRect(x: safe.leading + margin, y: safe.top + margin, width: width, height: height)

    content
      .environment(\.floatingPanelInsets, insets)
      .preference(key: FloatingPanelGeometryKey.self, value: isPanelVisible ? panelFrame : .zero)
      .overlay(alignment: .topTrailing) {
        VStack(alignment: .trailing, spacing: Self.taskbarGap) {
          if let taskbar {
            TemporaryTaskbar(style: style, taskbar: taskbar)
              .transition(.move(edge: .top).combined(with: .opacity))
          }
          if configuration.showsMapOverlayButtons {
            buttonStack
          }
        }
        .padding(.top, safe.top + margin)
        .padding(.trailing, safe.trailing + margin)
        .animation(style.animation, value: taskbar?.id)
      }
      .overlay(alignment: .topLeading) {
        if isPanelVisible {
          FloatingCornerPanel(style: style,
                              width: width,
                              height: height,
                              tabs: tabs,
                              selection: $selection,
                              content: panelContent,
                              onResize: { translation, ended in
                                let start = cornerResizeStart ?? height
                                if cornerResizeStart == nil { cornerResizeStart = start }
                                cornerHeight = layout.clamped(start + translation)
                                if ended { cornerResizeStart = nil }
                              })
            .padding(.top, safe.top + margin)
            .padding(.leading, safe.leading + margin)
            .transition(.move(edge: .leading).combined(with: .opacity))
        }
      }
      .animation(style.animation, value: isPanelVisible)
  }

  private var buttonStack: some View {
    MapOverlayButtonStack(style: style,
                          kinds: configuration.mapOverlayButtons,
                          actions: actions,
                          showsVisibilityToggle: configuration.showsPanelVisibilityToggle,
                          isPanelVisible: $isPanelVisible)
  }
}
