import SwiftUI

public extension View {

  /// Floats a panel, a toast, and two free-space containers over this content,
  /// and reports what they cover through `controller`.
  ///
  /// Attach it to the full-bleed view that already ignores the safe area; the
  /// chrome keeps itself inside the safe area, and never resizes or pushes the
  /// content it floats over.
  ///
  /// ```swift
  /// MyContent()
  ///     .floatingPanel(panel) {
  ///         SectionBody(section)        // main
  ///     } bar: {
  ///         SectionPicker($section)     // bar
  ///     } panelTrailing: {
  ///         PanelButtonStack { PanelVisibilityToggle() }
  ///             .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
  ///     }
  /// ```
  ///
  /// `panelAligned:` and `panelTrailing:` are containers, not slots: each is
  /// handed a rectangle of the space the panel leaves free, and what goes
  /// where inside it is decided the ordinary way, with
  /// `.frame(maxWidth:maxHeight:alignment:)`. Content that fills neither
  /// dimension is centred.
  ///
  /// - Parameters:
  ///   - controller: the panel's state, and where its geometry is reported.
  ///   - main: the panel's upper slot. Collapses to nothing at `.minimized`.
  ///   - bar: the panel's bottom slot, visible at every detent.
  ///   - toast: a transient surface, top-centre, shown while
  ///     `controller.isToastVisible`.
  ///   - panelAligned: the container sharing the panel's column, anchored to
  ///     the panel's free edge — above a bottom sheet, below a floating corner
  ///     panel. It fades out as the panel grows to fill that column, and fades
  ///     back in when the panel is dragged smaller.
  ///   - panelTrailing: the container on the panel's trailing side. On a wide
  ///     layout that is the strip beside the panel; on a narrow one, where the
  ///     sheet spans the full width, it is the whole inset container and
  ///     floats over the sheet.
  func floatingPanel<Main: View, Bar: View, ToastContent: View, Aligned: View, Trailing: View>(
    _ controller: PanelController,
    @ViewBuilder main: @escaping () -> Main,
    @ViewBuilder bar: @escaping () -> Bar,
    @ViewBuilder toast: @escaping () -> ToastContent = { EmptyView() },
    @ViewBuilder panelAligned: @escaping () -> Aligned = { EmptyView() },
    @ViewBuilder panelTrailing: @escaping () -> Trailing = { EmptyView() }
  ) -> some View {
    modifier(FloatingPanelModifier(controller: controller, main: main, bar: bar, toast: toast,
                                   panelAligned: panelAligned, panelTrailing: panelTrailing))
  }
}

/// The shell. One `GeometryReader`, and one pass per state change that decides
/// the panel's height, every surface's frame, and the insets together — so the
/// chrome and the content underneath cannot disagree.
struct FloatingPanelModifier<Main: View, Bar: View, ToastContent: View,
                             Aligned: View, Trailing: View>: ViewModifier {

  let controller: PanelController
  let main: () -> Main
  let bar: () -> Bar
  let toast: () -> ToastContent
  let panelAligned: () -> Aligned
  let panelTrailing: () -> Trailing

  /// The live drag of the panel's free edge, positive downwards. SwiftUI
  /// resets it when the gesture ends.
  @State private var heightDrag: CGFloat = 0
  /// The wide panel's width between resizes, and the size the current resize
  /// started from.
  @State private var panelWidth: CGFloat?
  @State private var resizeStart: CGSize?
  /// Measured rather than estimated, once the panel has laid out once.
  @State private var barHeight: CGFloat?
  @State private var toastHeight: CGFloat = 0

  private var style: PanelStyle { controller.style }

  func body(content: Content) -> some View {
    GeometryReader { proxy in
      let layout = resolveLayout(in: proxy)

      // One full-container stack that ignores the safe area exactly once. Each
      // surface is then placed by alignment plus explicit safe-area padding, so
      // where it lands never depends on how SwiftUI resolves safe areas for
      // overlays — which is how a sheet ends up under the Dynamic Island.
      ZStack(alignment: .topLeading) {
        content
        place(panelAligned(), in: layout.alignedFrame, opacity: layout.alignedOpacity)
        place(panelTrailing(), in: layout.trailingFrame)
        placeToast(layout)
        placeScrim(layout)
        placePanel(layout)
      }
      .frame(width: layout.container.width, height: layout.container.height)
      .ignoresSafeArea()
      .environment(\.panelController, controller)
      // Reported from outside the view update: writing observable state during
      // `body` is a runtime warning and a source of layout loops.
      .onChange(of: layout.geometry, initial: true) { _, geometry in
        controller.report(geometry)
      }
    }
  }

  // MARK: - One pass

  private func resolveLayout(in proxy: GeometryProxy) -> ResolvedLayout {
    let safeArea = proxy.safeAreaInsets
    let container = CGSize(width: proxy.size.width + safeArea.leading + safeArea.trailing,
                           height: proxy.size.height + safeArea.top + safeArea.bottom)
    let mode = controller.layoutModeOverride ?? LayoutMode.resolve(width: container.width, style: style)
    let margin = style.edgeMargin(for: mode)
    let edge = EdgeInsets(margin: margin, clearing: safeArea)

    // A sheet floats one margin above the container's bottom edge rather than
    // above the safe area, so its bottom gap reads the same as its sides; its
    // *content* clears the home indicator instead.
    let sheetBottomClearance = margin
    let bottomInset = mode == .bottomSheet ? sheetBottomClearance : edge.bottom

    var layout = ResolvedLayout(
      mode: mode,
      container: container,
      safeArea: safeArea,
      margin: margin,
      edge: edge,
      heights: PanelHeights(availableHeight: container.height - edge.top - bottomInset,
                            detents: controller.detents,
                            barHeight: barHeight ?? style.barHeightEstimate,
                            style: style),
      widths: PanelWidths(configuredRange: style.panelWidthRange,
                          available: container.width - edge.leading - edge.trailing))

    switch mode {
    case .bottomSheet: resolveSheet(&layout)
    case .floatingCorner: resolveCornerPanel(&layout)
    }
    resolveToast(&layout)
    resolveRegions(&layout)

    layout.contentInsets = ChromeInsets.covering(panel: layout.panelFrame, in: container, mode: mode)
    return layout
  }

  /// Over its final approach to `.full` the sheet's side and bottom margins
  /// dissolve and it goes edge-to-edge; only the top clearance stays, so a
  /// sliver of content and the handle remain reachable.
  private func resolveSheet(_ layout: inout ResolvedLayout) {
    let bottomClearance = layout.margin
    let resting = layout.heights.resolved(controller.detent)
    let height = layout.heights.height(from: resting, draggedBy: heightDrag)
    let dissolve = layout.heights.dissolveProgress(atHeight: height)

    layout.sheetLeadingInset = layout.edge.leading * (1 - dissolve)
    layout.sheetTrailingInset = layout.edge.trailing * (1 - dissolve)
    layout.sheetBottomInset = bottomClearance * (1 - dissolve)
    // The sheet grows into the space the dissolving bottom margin frees, so its
    // top edge stays where the detent put it.
    layout.panelSize = CGSize(width: layout.container.width - layout.sheetLeadingInset - layout.sheetTrailingInset,
                              height: height + bottomClearance * dissolve)
    layout.barBottomInset = max(layout.safeArea.bottom - layout.sheetBottomInset, 0)
    // Concentric with the container: inset by the margin the radius shrinks by
    // the margin, and edge-to-edge it matches the screen's own curvature.
    layout.panelCornerRadii = style.panelCornerRadii(
      ContainerCornerRadius.concentric(inset: min(layout.sheetLeadingInset, layout.sheetTrailingInset),
                                       fallback: style.cornerRadius),
      mode: layout.mode)

    guard controller.isPanelVisible else { return }
    #if os(iOS)
    layout.scrimOpacity = style.scrimOpacity * dissolve
    #endif
    layout.panelFrame = CGRect(origin: CGPoint(x: layout.sheetLeadingInset,
                                               y: layout.container.height - bottomClearance - height),
                               size: layout.panelSize)
  }

  private func resolveCornerPanel(_ layout: inout ResolvedLayout) {
    let resting = layout.heights.resolved(controller.detent)
    layout.panelSize = CGSize(width: layout.widths.clamped(panelWidth ?? style.panelWidth),
                              height: layout.heights.height(from: resting, draggedBy: heightDrag))
    layout.panelCornerRadii = style.panelCornerRadii(
      ContainerCornerRadius.concentric(inset: layout.margin, fallback: style.cornerRadius),
      mode: layout.mode)

    guard controller.isPanelVisible else { return }
    layout.panelFrame = CGRect(origin: CGPoint(x: layout.edge.leading, y: layout.edge.top),
                               size: layout.panelSize)
  }

  /// The toast belongs to the container on both layouts: the panel's width on
  /// narrow, so the two align on either edge; its own width on wide, centred
  /// in the strip left free beside the panel. It keeps its margins through a
  /// sheet's dissolve — the two surfaces are independent.
  private func resolveToast(_ layout: inout ResolvedLayout) {
    let container = layout.container
    let edge = layout.edge
    let originX: CGFloat
    let width: CGFloat

    switch layout.mode {
    case .bottomSheet:
      originX = edge.leading
      width = max(container.width - edge.leading - edge.trailing, 0)
    case .floatingCorner:
      let span = ToastSpan(containerWidth: container.width,
                           stripLeading: layout.panelFrame.isEmpty ? edge.leading : layout.panelFrame.maxX + layout.margin,
                           stripTrailing: container.width - edge.trailing,
                           preferredWidth: style.toastWidth)
      originX = span.originX
      width = span.width
    }
    layout.toastOriginX = originX
    layout.toastWidth = width

    guard controller.isToastVisible else { return }
    layout.toastFrame = CGRect(x: originX, y: edge.top, width: width, height: toastHeight)
  }

  /// The two containers, measured from the frames the pass has already settled
  /// — so neither can disagree with the panel or the toast about where they are.
  private func resolveRegions(_ layout: inout ResolvedLayout) {
    let regions = PanelRegions(
      mode: layout.mode,
      container: layout.container,
      edge: layout.edge,
      panelFrame: layout.panelFrame,
      panelWidth: layout.panelSize.width,
      contentTop: layout.toastFrame.isEmpty ? layout.edge.top : layout.toastFrame.maxY + style.surfaceSpacing,
      spacing: style.surfaceSpacing,
      fadeDistance: style.alignedFadeDistance)
    layout.alignedFrame = regions.aligned
    layout.trailingFrame = regions.trailing
    layout.alignedOpacity = regions.alignedOpacity
  }

  // MARK: - Placing what the pass decided

  /// A container: the consumer's content, given a rectangle of free space and
  /// left to align itself inside it.
  private func place<Content: View>(_ content: Content, in frame: CGRect,
                                    opacity: Double = 1) -> some View {
    content
      .frame(width: frame.width, height: frame.height)
      .opacity(opacity)
      // A faded-out area is gone, not merely invisible: the panel that grew
      // over it takes the taps.
      .allowsHitTesting(opacity > 0)
      .padding(.leading, frame.minX)
      .padding(.top, frame.minY)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .animation(style.animation, value: controller.isPanelVisible)
  }

  /// Under the panel and over everything else, so the whole screen recedes
  /// behind a sheet at `.full` while the sheet itself stays bright. It only
  /// dims: taps go through to whatever it covers.
  private func placeScrim(_ layout: ResolvedLayout) -> some View {
    Color.black
      .opacity(layout.scrimOpacity)
      .allowsHitTesting(false)
      .animation(style.animation, value: controller.isPanelVisible)
  }

  /// The container stays put whether or not the panel does, so the transition
  /// has something to animate on. An `.animation` inside the branch would be
  /// torn down with the view it was meant to move.
  private func placePanel(_ layout: ResolvedLayout) -> some View {
    let alignment: Alignment = layout.mode == .bottomSheet ? .bottom : .topLeading
    return ZStack(alignment: alignment) {
      if controller.isPanelVisible {
        panelBody(layout)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    .animation(style.animation, value: controller.isPanelVisible)
  }

  @ViewBuilder
  private func panelBody(_ layout: ResolvedLayout) -> some View {
    switch layout.mode {
    case .bottomSheet:
      BottomSheetPanel(style: style,
                       height: layout.panelSize.height,
                       cornerRadii: layout.panelCornerRadii,
                       barBottomInset: layout.barBottomInset,
                       main: { main() },
                       bar: { bar() },
                       onBarHeightChange: { barHeight = $0 },
                       onDragChanged: { heightDrag = $0 },
                       onDragEnded: { settleHeight(layout, projecting: $0) })
        .padding(.leading, layout.sheetLeadingInset)
        .padding(.trailing, layout.sheetTrailingInset)
        .padding(.bottom, layout.sheetBottomInset)
        // A slide with no fade: the panel is not disappearing, it is leaving.
        .transition(.move(edge: .bottom))

    case .floatingCorner:
      FloatingCornerPanel(style: style,
                          size: layout.panelSize,
                          cornerRadii: layout.panelCornerRadii,
                          main: { main() },
                          bar: { bar() },
                          onResize: { edge, translation, projected in
                            resize(layout, edge: edge, translation: translation, projecting: projected)
                          })
        .padding(.top, layout.edge.top)
        .padding(.leading, layout.edge.leading)
        .transition(.move(edge: .leading))
    }
  }

  private func placeToast(_ layout: ResolvedLayout) -> some View {
    // The container stays put so the toast's arrival and departure animate.
    ZStack(alignment: .topLeading) {
      if controller.isToastVisible {
        Toast(style: style) { toast() }
          .frame(width: layout.toastWidth)
          .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { toastHeight = $0 }
          .padding(.leading, layout.toastOriginX)
          .transition(.move(edge: .top).combined(with: .opacity))
      }
    }
    .padding(.top, layout.edge.top)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .animation(style.animation, value: controller.isToastVisible)
  }

  // MARK: - Gestures

  /// A released height drag lands on the detent nearest its projected stop.
  private func settleHeight(_ layout: ResolvedLayout, projecting projected: CGFloat) {
    let resting = layout.heights.resolved(controller.detent)
    let next = layout.heights.snappedDetent(from: resting, projecting: projected)
    withAnimation(style.animation) {
      controller.detent = next
      heightDrag = 0
    }
  }

  /// The wide panel's grips: width stays wherever it is dropped, height is a
  /// detent and so snaps like a sheet's drag.
  private func resize(_ layout: ResolvedLayout, edge: ResizeEdge,
                      translation: CGSize, projecting projected: CGSize?) {
    let start = resizeStart ?? layout.panelSize
    resizeStart = start

    if edge.affectsWidth {
      panelWidth = layout.widths.clamped(start.width + translation.width)
    }
    // Dragging the bottom edge down grows the wide panel, where dragging a
    // sheet down shrinks it. Negated here, once, so everything downstream —
    // the live height and the snap alike — reads the one convention.
    if edge.affectsHeight {
      heightDrag = -translation.height
    }

    guard let projected else { return }
    resizeStart = nil
    if edge.affectsHeight {
      settleHeight(layout, projecting: -projected.height)
    }
  }
}

/// Everything one layout pass decided, read by every surface so no two of them
/// compute the same number differently.
private struct ResolvedLayout {

  let mode: LayoutMode
  let container: CGSize
  let safeArea: EdgeInsets
  /// The chrome's distance from the container's edges, before the safe area.
  let margin: CGFloat
  /// Where the chrome actually sits relative to each container edge.
  let edge: EdgeInsets
  let heights: PanelHeights
  let widths: PanelWidths

  /// The size the panel is drawn at, whether or not it is on screen — an
  /// outgoing panel keeps it, so it slides out at full size rather than
  /// collapsing to nothing.
  var panelSize: CGSize = .zero
  var panelCornerRadii = RectangleCornerRadii(0)
  /// The toast's placement.
  var toastOriginX: CGFloat = 0
  var toastWidth: CGFloat = 0
  var barBottomInset: CGFloat = 0
  var sheetLeadingInset: CGFloat = 0
  var sheetTrailingInset: CGFloat = 0
  var sheetBottomInset: CGFloat = 0
  /// How solid the aligned area is, given how far the panel has grown into it.
  var alignedOpacity: Double = 1
  /// How dark the screen behind the panel is. Zero everywhere but a sheet
  /// near `.full` on iOS.
  var scrimOpacity: Double = 0

  var panelFrame: CGRect = .zero
  var toastFrame: CGRect = .zero
  var alignedFrame: CGRect = .zero
  var trailingFrame: CGRect = .zero
  var contentInsets: EdgeInsets = EdgeInsets()

  /// The part the controller publishes, so a change it does not report — a
  /// corner radius mid-dissolve — never churns the consumer's observation.
  var geometry: ChromeGeometry {
    ChromeGeometry(layoutMode: mode, contentInsets: contentInsets, panelFrame: panelFrame,
                   toastFrame: toastFrame, panelAlignedFrame: alignedFrame,
                   panelTrailingFrame: trailingFrame)
  }
}
