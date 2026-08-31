import SwiftUI

/// The panel's tabbed body: the content above the package's own bottom tab
/// bar. One implementation on every platform — the custom bar draws inside
/// the panel's material, which a native `TabView` cannot be relied on to do
/// at these deployment targets.
struct PanelTabs<Content: View>: View {

  let tabs: [FloatingPanelTab]
  @Binding var selection: FloatingPanelTab.ID
  /// Extra room under the tab bar — the sheet's home-indicator clearance.
  var bottomInset: CGFloat = 0
  /// Reports the bar's height (divider, tabs, `bottomInset`), so the sheet
  /// can size its collapsed state to exactly the chrome.
  var onBarHeightChange: ((CGFloat) -> Void)? = nil
  /// Forwarded to the tab bar; fires on every tab press.
  var onTabTap: (() -> Void)? = nil
  let content: (FloatingPanelTab.ID) -> Content

  var body: some View {
    VStack(spacing: 0) {
      // An explicit zero minimum lets the area collapse below the content's
      // own minimum; clipped, so a collapsing sheet never shows a sliver of
      // content spilling out of the shrinking area above the bar.
      content(selection)
        .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .clipped()
      VStack(spacing: 0) {
        Divider()
        FloatingPanelTabBar(tabs: tabs, selection: $selection, onTap: onTabTap)
      }
      .padding(.bottom, bottomInset)
      .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { onBarHeightChange?($0) }
    }
  }
}
