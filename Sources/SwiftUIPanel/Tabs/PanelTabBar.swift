import SwiftUI

/// Icon-over-label tabs for the panel's bar slot, on every platform — rather
/// than the Mac's usual sidebar.
///
/// The tabs share the bar's width evenly, inside `PanelStyle.tabBarPaddingHorizontal`
/// at either end, so the space between them follows the width of the panel: an
/// ordinary `HStack` of equal, flexible columns, with nothing measured.
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
      HStack(spacing: 0) {
        ForEach(tabs) { tab in
          tabButton(tab)
        }
      }
      .padding(.horizontal, style.tabBarPaddingHorizontal)
      .padding(.top, style.tabBarPaddingTop)
      .padding(.bottom, style.tabBarPaddingBottom)
    }
  }

  private func tabButton(_ tab: PanelTab<ID>) -> some View {
    let isSelected = selection == tab.id
    return Button {
      selection = tab.id
      openIfMinimized()
    } label: {
      VStack(spacing: style.tabLabelSpacing) {
        Image(systemName: tab.systemImage)
          .font(.title3.weight(.medium))
          .frame(height: style.tabIconHeight * iconScale)
        Text(LocalizedStringKey(tab.title))
          .font(.caption2)
          .lineLimit(1)
          // A column narrower than its label shrinks the label a little before it truncates.
          .minimumScaleFactor(0.8)
      }
      .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
      // Every tab takes an equal share of the row, so the gaps between them are whatever the
      // panel's width leaves.
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
