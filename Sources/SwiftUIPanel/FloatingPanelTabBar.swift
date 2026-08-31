import SwiftUI

/// Icon-over-label tabs, pinned to the panel's bottom on every platform —
/// rather than the usual Mac sidebar arrangement.
struct FloatingPanelTabBar: View {

  let tabs: [FloatingPanelTab]
  @Binding var selection: FloatingPanelTab.ID
  /// Fires on every tab press, the already-selected tab included — how a
  /// collapsed sheet knows to open.
  var onTap: (() -> Void)? = nil

  /// Semantic fonts plus a scaled slot height, so the bar follows the user's
  /// type size.
  @ScaledMetric(relativeTo: .title3) private var iconHeight: CGFloat = 22

  var body: some View {
    HStack(spacing: 0) {
      ForEach(tabs) { tab in
        Button {
          selection = tab.id
          onTap?()
        } label: {
          VStack(spacing: 3) {
            Image(systemName: tab.systemImage)
              .font(.title3.weight(.medium))
              .frame(height: iconHeight)
            Text(tab.title)
              .font(.caption2)
          }
          .foregroundStyle(selection == tab.id ? Color.accentColor : Color.secondary)
          .frame(maxWidth: .infinity)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(selection == tab.id ? [.isSelected] : [])
      }
    }
    .padding(.top, 6)
    .padding(.bottom, 4)
  }
}
