import SwiftUI

/// The panel's tabbed body.
///
/// iOS and iPadOS use the native `TabView` — a real `UITabBar`, with its own
/// background hidden so the panel's material shows through. macOS keeps the
/// package's bottom bar: a `TabView` there can only draw top segmented tabs at
/// these deployment targets, and Maps-style bottom tabs are the point.
struct PanelTabs<Content: View>: View {

  let tabs: [FloatingPanelTab]
  @Binding var selection: FloatingPanelTab.ID
  let content: (FloatingPanelTab.ID) -> Content

  var body: some View {
    #if os(macOS)
    VStack(spacing: 0) {
      content(selection)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      Divider()
      FloatingPanelTabBar(tabs: tabs, selection: $selection)
    }
    #else
    TabView(selection: $selection) {
      ForEach(tabs) { tab in
        content(tab.id)
          .tabItem { Label(tab.title, systemImage: tab.systemImage) }
          .tag(tab.id)
      }
    }
    .toolbarBackground(.hidden, for: .tabBar)
    #endif
  }
}
