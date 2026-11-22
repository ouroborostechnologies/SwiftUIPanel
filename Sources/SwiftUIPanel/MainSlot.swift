import SwiftUI

/// The panel's main slot. It fills whatever height the panel gives it — or,
/// on a focused panel, takes the height its content asks for.
///
/// A fitted slot asks its content for its ideal height first. A `ScrollView`
/// answers with its content's; a `List` or a `Form` has no height of its own to
/// ask for and answers zero, so for those the slot reads the content height of
/// the first scroll view inside it instead. Asking first matters when focusing
/// swaps the content: the last reading is of the scroll view that was there
/// before, and fitting to it would size the panel for content already gone,
/// then size it again once the new one reports. Either way it stops at
/// `fittingHeight`; past that, a scroll view scrolls and anything else is
/// clipped. A fitted slot's size never depends on the height it is offered, so
/// the panel can be sized from it without the two chasing each other.
///
/// One view for both, so the consumer's content keeps its identity — and its
/// state — when the panel is focused and back.
struct MainSlot<Content: View>: View {

  /// The most a fitted slot may take. `nil` fills the panel instead.
  let fittingHeight: CGFloat?
  @ViewBuilder let content: Content

  @State private var scrollContentHeight: CGFloat?

  var body: some View {
    MainSlotLayout(fittingHeight: fittingHeight, scrollContentHeight: scrollContentHeight) {
      content
    }
    // Clipping stops a shrinking panel showing a sliver spilling past its
    // edge.
    .clipped()
    // The content alone, not its insets: those grow with whatever safe area
    // the scroll view overlaps, and a panel springing to a new height
    // overlaps the home indicator by a different amount on every frame — so
    // a fit that counted them would re-measure, re-animate, and never settle.
    .onScrollGeometryChange(for: CGFloat.self) { $0.contentSize.height } action: { _, height in
      scrollContentHeight = height > 0 ? height : nil
    }
  }
}

private struct MainSlotLayout: Layout {

  let fittingHeight: CGFloat?
  let scrollContentHeight: CGFloat?

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    guard let subview = subviews.first else { return .zero }
    guard let fittingHeight else {
      // Whatever it is offered, down to nothing: a zero minimum lets the slot
      // collapse below its content's own.
      if let width = proposal.width, let height = proposal.height { return CGSize(width: width, height: height) }
      return proposal.replacingUnspecifiedDimensions(by: subview.sizeThatFits(.unspecified))
    }
    let ideal = subview.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))
    // A list that has not reported yet has no height at all. Holding the
    // height it was offered keeps the panel still until it does, rather than
    // collapsing it for a frame.
    let height = ideal.height > 0 ? ideal.height : scrollContentHeight ?? proposal.height ?? 0
    return CGSize(width: proposal.width ?? ideal.width,
                  height: min(max(height, 0), max(fittingHeight, 0)))
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    subviews.first?.place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(bounds.size))
  }
}

/// Reports the height of whatever it is the background of, for as long as it
/// is there.
///
/// Inserted only while the panel is focused, so its first report is always of
/// a fitted slot — never a stale one measured while the slot filled the panel
/// — and it reports even when focusing left that height unchanged.
struct FittedHeightProbe: View {

  let onChange: (CGFloat) -> Void

  var body: some View {
    Color.clear
      .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { onChange($0) }
  }
}
