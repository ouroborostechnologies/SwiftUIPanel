import SwiftUI

/// Icon-over-label tabs, pinned to the panel's bottom on every platform —
/// matching Maps rather than the usual Mac sidebar.
struct FloatingPanelTabBar: View {

  let tabs: [FloatingPanelTab]
  @Binding var selection: FloatingPanelTab.ID

  var body: some View {
    HStack(spacing: 0) {
      ForEach(tabs) { tab in
        Button {
          selection = tab.id
        } label: {
          VStack(spacing: 3) {
            Image(systemName: tab.systemImage)
              .font(.system(size: 20, weight: .medium))
              .frame(height: 24)
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
