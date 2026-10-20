import SwiftUI

/// Icon-over-label tabs for the panel's bar slot, on every platform — rather
/// than the Mac's usual sidebar.
///
/// As the bar narrows, the space between tabs gives way first: equal columns
/// while the widest label fits one, then each label at its own width with the
/// rest shared out. A bar too narrow for every label shows icons alone, each
/// still labelled for accessibility.
///
/// `View.floatingPanel(_:tabs:selection:main:toast:panelAligned:panelTrailing:)`
/// fills the bar with one of these. Place it in `bar:` yourself when you want the standard
/// bar but a `main:` of your own.
public struct PanelTabBar<ID: Hashable>: View {

  private let tabs: [PanelTab<ID>]
  @Binding private var selection: ID

  @Environment(\.panelController) private var controller
  /// Grows the icon slot with the user's type size; the fonts are semantic and
  /// follow on their own.
  @ScaledMetric(relativeTo: .title3) private var iconScale: CGFloat = 1

  public init(_ tabs: [PanelTab<ID>], selection: Binding<ID>) {
    self.tabs = tabs
    self._selection = selection
  }

  private var style: PanelStyle { controller?.style ?? .default }

  public var body: some View {
    VStack(spacing: 0) {
      Divider()
      ViewThatFits(in: .horizontal) {
        row(showsTitles: true)
        row(showsTitles: false)
      }
      .padding(.top, style.tabBarPaddingTop)
      .padding(.bottom, style.tabBarPaddingBottom)
    }
  }

  private func row(showsTitles: Bool) -> some View {
    TabBarLayout {
      ForEach(tabs) { tab in
        tabButton(tab, showsTitle: showsTitles)
      }
    }
  }

  private func tabButton(_ tab: PanelTab<ID>, showsTitle: Bool) -> some View {
    let isSelected = selection == tab.id
    return Button {
      selection = tab.id
      openIfMinimized()
    } label: {
      VStack(spacing: style.tabLabelSpacing) {
        Image(systemName: tab.systemImage)
          .font(.title3.weight(.medium))
          .frame(height: style.tabIconHeight * iconScale)
        if showsTitle {
          Text(LocalizedStringKey(tab.title))
            .font(.caption2)
            .lineLimit(1)
        }
      }
      // Half the minimum gap on either side, so it is part of the width each
      // tab asks for and two labels can never meet.
      .padding(.horizontal, style.tabMinimumSpacing / 2)
      .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
      .frame(maxWidth: .infinity)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(LocalizedStringKey(tab.title))
    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
  }

  /// A press on any tab — the selected one included — opens a minimized panel,
  /// since a bar switching invisible content helps no one. Written through the
  /// controller, exactly as a bar of your own could.
  private func openIfMinimized() {
    guard let controller else { return }
    let ascending = controller.detents.sorted { $0.fraction < $1.fraction }
    guard let smallest = ascending.first, controller.detent == smallest else { return }
    withAnimation(controller.style.animation) {
      controller.detent = ascending[min(1, ascending.count - 1)]
    }
  }
}

/// Lays tabs out in a row that fills the width it is offered, without ever
/// narrowing a tab below the width it asks for.
///
/// Every tab gets the same share of the row, except a tab wider than that
/// share, which keeps its own width while the rest share what is left. So the
/// columns are equal while they can be, and as the row narrows the space
/// around the shortest labels goes first — continuously, with no jump between
/// the two. Its ideal width is the tabs' own widths summed: the least it can
/// draw every tab in, which is what lets `ViewThatFits` choose a smaller row.
struct TabBarLayout: Layout {

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
    let natural = sizes.reduce(0) { $0 + $1.width }
    let height = sizes.map(\.height).max() ?? 0
    guard let width = proposal.width, width.isFinite else { return CGSize(width: natural, height: height) }
    return CGSize(width: max(width, natural), height: height)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let widths = subviews.map { $0.sizeThatFits(.unspecified).width }
    let columns = Self.columnWidths(for: widths, filling: bounds.width)
    var x = bounds.minX
    for (subview, width) in zip(subviews, columns) {
      subview.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading,
                    proposal: ProposedViewSize(width: width, height: bounds.height))
      x += width
    }
  }

  /// Each tab's column: an equal share of `available`, or the tab's own width
  /// where that is more. The share is found by setting aside every tab wider
  /// than it, widest first, and dividing what remains among the others.
  static func columnWidths(for widths: [CGFloat], filling available: CGFloat) -> [CGFloat] {
    var remaining = available
    var sharing = widths.count
    for width in widths.sorted(by: >) where sharing > 0 && width > remaining / CGFloat(sharing) {
      remaining -= width
      sharing -= 1
    }
    let share = sharing > 0 ? remaining / CGFloat(sharing) : 0
    return widths.map { max($0, share) }
  }
}
