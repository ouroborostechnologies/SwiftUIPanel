import SwiftUI

public extension View {

  /// Overlays a floating panel, tab bar, overlay buttons, and optional
  /// taskbar on this full-bleed content, and publishes what they cover via
  /// `\.floatingPanelInsets` (and `FloatingPanelGeometryKey` for raw frames).
  ///
  /// Attach it to the content itself — the view that already ignores the
  /// safe area. The chrome stays inside the safe area on its own.
  ///
  /// - Parameters:
  ///   - taskbar: `nil` hides the taskbar. On iPhone its presence forces the
  ///     sheet to its smallest detent.
  func floatingPanel<Content: View>(
    configuration: Configuration = .default,
    tabs: [FloatingPanelTab],
    selection: Binding<FloatingPanelTab.ID>,
    isPanelVisible: Binding<Bool> = .constant(true),
    taskbar: TemporaryTaskbarContent? = nil,
    @ViewBuilder content: @escaping (FloatingPanelTab.ID) -> Content
  ) -> some View {
    modifier(FloatingPanelModifier(configuration: configuration,
                                   tabs: tabs,
                                   selection: selection,
                                   isPanelVisible: isPanelVisible,
                                   taskbar: taskbar,
                                   panelContent: content))
  }
}

/// The whole shell. One `GeometryReader`, one pass per state change that
/// yields the sheet height, the corner height, the insets, and the frames —
/// so the content underneath and the chrome on top can never disagree.
struct FloatingPanelModifier<PanelContent: View>: ViewModifier {

  let configuration: Configuration
  let tabs: [FloatingPanelTab]
  @Binding var selection: FloatingPanelTab.ID
  @Binding var isPanelVisible: Bool
  let taskbar: TemporaryTaskbarContent?
  let panelContent: (FloatingPanelTab.ID) -> PanelContent

  /// The sheet's detent between drags.
  @State private var restingDetent: Detent?
  /// The live drag, positive downwards. Reset by SwiftUI when the gesture ends.
  @State private var sheetDrag: CGFloat = 0
  @State private var cornerSize: CGSize?
  @State private var cornerResizeStart: CGSize?
  @State private var taskbarHeight: CGFloat = 0
  /// The sheet's measured handle + tab bar + bottom inset — the height of
  /// `.minimized`, where only the tab bar shows. The estimate holds for the
  /// first frame; the measurement replaces it before anything is visible.
  @State private var sheetChromeHeight: CGFloat = 76

  static var taskbarGap: CGFloat { 8 }

  private var style: PanelStyle { configuration.style }

  func body(content: Content) -> some View {
    GeometryReader { geometry in
      let safe = geometry.safeAreaInsets
      let full = CGSize(width: geometry.size.width + safe.leading + safe.trailing,
                        height: geometry.size.height + safe.top + safe.bottom)
      let mode = PlatformIdiom.resolve(override: configuration.layoutModeOverride, width: full.width,
                                       breakpoints: configuration.layoutBreakpoints)
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
      .environment(\.floatingPanelLayoutMode, mode)
    }
  }

  // MARK: - iPhone

  @ViewBuilder
  private func bottomSheetLayout(content: Content, full: CGSize, safe: EdgeInsets, margin: CGFloat) -> some View {
    // The sheet floats one margin from the display's edges — the bottom gap
    // is measured from the display, not the safe area, so it reads the same
    // as the sides; the sheet's *content* keeps clear of the home indicator
    // instead. The sides use the chrome insets: the margin, unless the safe area
    // (Dynamic Island in landscape) asks for more. Over its final approach to
    // `.full` the side and bottom margins dissolve and it goes edge-to-edge;
    // only the top clearance stays, so a sliver of content remains visible
    // and the handle stays reachable.
    let edge = EdgeInsets(chromeSafe: safe, margin: margin)
    let bottomClearance = margin
    let layout = SheetLayout(availableHeight: full.height - edge.top - bottomClearance,
                             detents: configuration.detents,
                             chromeHeight: sheetChromeHeight)
    let resting = restingDetent ?? (layout.contains(configuration.initialDetent) ? configuration.initialDetent : layout.smallest)
    // One derived state: a taskbar forces the smallest detent and suspends
    // dragging, so the two surfaces never animate against each other.
    let effective = taskbar == nil ? resting : layout.smallest
    let sheetHeight = isPanelVisible ? layout.displayedHeight(resting: effective, dragTranslation: taskbar == nil ? sheetDrag : 0) : 0
    let progress = layout.fullScreenProgress(displayedHeight: sheetHeight)
    let leadingInset = edge.leading * (1 - progress)
    let trailingInset = edge.trailing * (1 - progress)
    let bottomInset = bottomClearance * (1 - progress)
    // As the bottom margin collapses the sheet grows to fill the freed space,
    // so its top edge stays where the detent math put it.
    let displayedHeight = sheetHeight + bottomClearance * progress
    // Concentric with the display: inset by the margin, the radius shrinks by
    // the margin, and edge-to-edge it matches the screen's own curvature.
    let cornerRadius = ContainerCornerRadius.concentric(inset: min(leadingInset, trailingInset), fallback: style.cornerRadius)
    let insets = PanelInsets.bottomSheet(sheetHeight: sheetHeight,
                                         taskbarHeight: taskbar == nil ? nil : taskbarHeight,
                                         gap: Self.taskbarGap,
                                         bottomClearance: bottomClearance)
    let sheetFrame = CGRect(x: leadingInset,
                            y: full.height - bottomClearance - sheetHeight,
                            width: full.width - leadingInset - trailingInset,
                            height: displayedHeight)

    content
      .environment(\.floatingPanelInsets, insets)
      .preference(key: FloatingPanelGeometryKey.self, value: isPanelVisible ? sheetFrame : .zero)

    if configuration.showsOverlayButtons {
      buttonStack
        .padding(.top, edge.top)
        .padding(.trailing, edge.trailing)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    VStack(spacing: Self.taskbarGap) {
      if let taskbar {
        TemporaryTaskbar(style: style, taskbar: taskbar)
          .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { taskbarHeight = $0 }
          .padding(.leading, edge.leading)
          .padding(.trailing, edge.trailing)
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
      if isPanelVisible {
        BottomSheetPanel(style: style,
                         tabs: tabs,
                         selection: $selection,
                         displayedHeight: displayedHeight,
                         cornerRadius: cornerRadius,
                         bottomSafeInset: max(safe.bottom - bottomInset, 0),
                         isDraggable: taskbar == nil,
                         content: panelContent,
                         onChromeHeightChange: { sheetChromeHeight = $0 },
                         onTabTapped: {
                           // Fully closed, a tab press opens the sheet — a
                           // bare tab bar switching invisible content helps
                           // no one. A taskbar keeps it closed, though; it
                           // owns the room.
                           guard taskbar == nil, resting == layout.smallest else { return }
                           withAnimation(style.animation) { restingDetent = layout.openedFromCollapsed }
                         },
                         onDragChanged: { sheetDrag = $0 },
                         onDragEnded: { predicted in
                           let next = layout.snappedDetent(resting: resting, predictedTranslation: predicted)
                           withAnimation(style.animation) {
                             restingDetent = next
                             sheetDrag = 0
                           }
                         })
          .padding(.leading, leadingInset)
          .padding(.trailing, trailingInset)
          .transition(.move(edge: .bottom))
      }
    }
    // A lone taskbar has no content inset of its own, so it stays above the
    // home indicator; the sheet handles the safe area internally.
    .padding(.bottom, isPanelVisible ? bottomInset : edge.bottom)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    .animation(style.animation, value: taskbar?.id)
    .animation(style.animation, value: isPanelVisible)
  }

  // MARK: - iPad and Mac

  @ViewBuilder
  private func floatingCornerLayout(content: Content, full: CGSize, safe: EdgeInsets, margin: CGFloat) -> some View {
    // One margin from each display edge, grown only where the safe area asks
    // for more. Never taller than the window, never wide enough to reach the
    // button stack.
    let edge = EdgeInsets(chromeSafe: safe, margin: margin)
    let stackAllowance = configuration.showsOverlayButtons ? style.buttonDiameter + margin : 0
    let layout = CornerLayout(configuredHeightRange: configuration.cornerPanelHeightRange,
                              configuredWidthRange: configuration.cornerPanelWidthRange,
                              availableHeight: full.height - edge.top - edge.bottom,
                              availableWidth: full.width - edge.leading - edge.trailing - stackAllowance)
    let size = layout.clamped(cornerSize ?? CGSize(width: configuration.cornerPanelWidth,
                                                   height: configuration.initialCornerPanelHeight))
    // Concentric with the container — the display's corners on iPad, the
    // window's on the Mac — where its curvature allows, else the style's own.
    let cornerRadius = ContainerCornerRadius.concentric(inset: margin, fallback: style.cornerRadius)
    let insets = isPanelVisible
      ? PanelInsets.floatingCorner(leadingInset: edge.leading, width: size.width)
      : EdgeInsets()
    let panelFrame = CGRect(x: edge.leading, y: edge.top, width: size.width, height: size.height)

    content
      .environment(\.floatingPanelInsets, insets)
      .preference(key: FloatingPanelGeometryKey.self, value: isPanelVisible ? panelFrame : .zero)

    if configuration.showsOverlayButtons {
      buttonStack
        .padding(.top, edge.top)
        .padding(.trailing, edge.trailing)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    // The taskbar reads as the window's, not the panel's: top centre, sized
    // from the configuration and capped by the strip left free between the
    // panel's trailing edge and the button stack. Both gaps are one margin,
    // so even a taskbar wide enough to fill the strip keeps its distance.
    let span = TaskbarSpan(containerWidth: full.width,
                           leading: isPanelVisible ? edge.leading + size.width + margin : edge.leading,
                           trailing: full.width - edge.trailing - stackAllowance,
                           preferredWidth: configuration.taskbarWidth)

    ZStack(alignment: .topLeading) {
      if let taskbar {
        TemporaryTaskbar(style: style, taskbar: taskbar)
          .frame(width: span.width)
          .padding(.leading, span.originX)
          .transition(.move(edge: .top).combined(with: .opacity))
      }
    }
    .padding(.top, edge.top)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .animation(style.animation, value: taskbar?.id)

    if isPanelVisible {
      FloatingCornerPanel(style: style,
                          size: size,
                          cornerRadius: cornerRadius,
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
        .padding(.top, edge.top)
        .padding(.leading, edge.leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .transition(.move(edge: .leading).combined(with: .opacity))
        .animation(style.animation, value: isPanelVisible)
    }
  }

  private var buttonStack: some View {
    OverlayButtonStack(style: style,
                       kinds: configuration.overlayButtons,
                       showsVisibilityToggle: configuration.showsPanelVisibilityToggle,
                       isPanelVisible: $isPanelVisible)
  }
}
