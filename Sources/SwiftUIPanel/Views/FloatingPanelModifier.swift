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
  @State private var cornerSize: CGSize?
  @State private var cornerResizeStart: CGSize?
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

      // One full-window stack that ignores the safe area exactly once. Every
      // surface is then placed by alignment plus *explicit* safe-area padding,
      // so where the chrome lands never depends on how SwiftUI resolves safe
      // areas for overlays — which is how a sheet ends up under the Dynamic
      // Island.
      ZStack(alignment: .topLeading) {
        switch mode {
        case .bottomSheet:
          bottomSheetLayout(content: content, full: full, safe: safe, margin: margin)
        case .floatingCorner:
          floatingCornerLayout(content: content, full: full, safe: safe, margin: margin)
        }
      }
      .frame(width: full.width, height: full.height)
      .ignoresSafeArea()
    }
  }

  // MARK: - iPhone

  @ViewBuilder
  private func bottomSheetLayout(content: Content, full: CGSize, safe: EdgeInsets, margin: CGFloat) -> some View {
    // The sheet lives inside the safe area plus a margin on every side, so at
    // `.full` the Dynamic Island and a sliver of map stay visible and the
    // handle is always reachable.
    let bottomClearance = safe.bottom + margin
    let layout = SheetLayout(availableHeight: full.height - safe.top - bottomClearance - margin,
                             detents: configuration.detents)
    let resting = restingDetent ?? (layout.contains(configuration.initialDetent) ? configuration.initialDetent : layout.smallest)
    // One derived state: a taskbar forces the smallest detent and suspends
    // dragging, so the two surfaces never animate against each other.
    let effective = taskbar == nil ? resting : layout.smallest
    let sheetHeight = isPanelVisible ? layout.displayedHeight(resting: effective, dragTranslation: taskbar == nil ? sheetDrag : 0) : 0
    let insets = PanelInsets.bottomSheet(sheetHeight: sheetHeight,
                                         taskbarHeight: taskbar == nil ? nil : taskbarHeight,
                                         gap: Self.taskbarGap,
                                         bottomClearance: bottomClearance)
    let sheetFrame = CGRect(x: safe.leading + margin,
                            y: full.height - bottomClearance - sheetHeight,
                            width: full.width - safe.leading - safe.trailing - margin * 2,
                            height: sheetHeight)

    content
      .environment(\.floatingPanelInsets, insets)
      .preference(key: FloatingPanelGeometryKey.self, value: isPanelVisible ? sheetFrame : .zero)

    if configuration.showsMapOverlayButtons {
      buttonStack
        .padding(.top, safe.top + margin)
        .padding(.trailing, safe.trailing + margin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    VStack(spacing: Self.taskbarGap) {
      if let taskbar {
        TemporaryTaskbar(style: style, taskbar: taskbar)
          .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { taskbarHeight = $0 }
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
      if isPanelVisible {
        BottomSheetPanel(style: style,
                         tabs: tabs,
                         selection: $selection,
                         displayedHeight: sheetHeight,
                         isDraggable: taskbar == nil,
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
    .padding(.leading, safe.leading + margin)
    .padding(.trailing, safe.trailing + margin)
    .padding(.bottom, bottomClearance)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    .animation(style.animation, value: taskbar?.id)
    .animation(style.animation, value: isPanelVisible)
  }

  // MARK: - iPad and Mac

  @ViewBuilder
  private func floatingCornerLayout(content: Content, full: CGSize, safe: EdgeInsets, margin: CGFloat) -> some View {
    // Never taller than the window, never wide enough to reach the button stack.
    let stackAllowance = configuration.showsMapOverlayButtons ? style.buttonDiameter + margin : 0
    let layout = CornerLayout(configuredHeightRange: configuration.cornerPanelHeightRange,
                              configuredWidthRange: configuration.cornerPanelWidthRange,
                              availableHeight: full.height - safe.top - safe.bottom - margin * 2,
                              availableWidth: full.width - safe.leading - safe.trailing - margin * 2 - stackAllowance)
    let size = layout.clamped(cornerSize ?? CGSize(width: configuration.cornerPanelWidth,
                                                   height: configuration.initialCornerPanelHeight))
    let insets = isPanelVisible
      ? PanelInsets.floatingCorner(safeLeading: safe.leading, margin: margin, width: size.width)
      : EdgeInsets()
    let panelFrame = CGRect(x: safe.leading + margin, y: safe.top + margin, width: size.width, height: size.height)

    content
      .environment(\.floatingPanelInsets, insets)
      .preference(key: FloatingPanelGeometryKey.self, value: isPanelVisible ? panelFrame : .zero)

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
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    .animation(style.animation, value: taskbar?.id)

    if isPanelVisible {
      FloatingCornerPanel(style: style,
                          size: size,
                          tabs: tabs,
                          selection: $selection,
                          content: panelContent,
                          onResize: { edge, translation, predicted in
                            let start = cornerResizeStart ?? size
                            if cornerResizeStart == nil { cornerResizeStart = start }
                            var resized = layout.clamped(edge.apply(translation, to: start))
                            if let predicted {
                              // Released: width stays where it was dropped, height snaps.
                              if edge.affectsHeight, configuration.cornerPanelSnapsVertically {
                                resized.height = layout.snappedHeight(from: start.height,
                                                                      predictedTranslation: predicted.height,
                                                                      detents: configuration.detents)
                              }
                              cornerResizeStart = nil
                              withAnimation(style.animation) { cornerSize = resized }
                            } else {
                              cornerSize = resized
                            }
                          })
        .padding(.top, safe.top + margin)
        .padding(.leading, safe.leading + margin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .transition(.move(edge: .leading).combined(with: .opacity))
        .animation(style.animation, value: isPanelVisible)
    }
  }

  private var buttonStack: some View {
    MapOverlayButtonStack(style: style,
                          kinds: configuration.mapOverlayButtons,
                          actions: actions,
                          showsVisibilityToggle: configuration.showsPanelVisibilityToggle,
                          isPanelVisible: $isPanelVisible)
  }
}
