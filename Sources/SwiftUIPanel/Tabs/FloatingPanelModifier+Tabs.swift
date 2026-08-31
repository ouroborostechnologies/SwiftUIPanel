import SwiftUI

public extension View {

  /// Floats a panel whose bar slot is a tab bar, and whose main slot is handed
  /// the selected tab.
  ///
  /// ```swift
  /// MyContent()
  ///     .floatingPanel(panel, tabs: tabs, selection: $section) { section in
  ///         SectionBody(section)
  ///     } buttons: {
  ///         PanelVisibilityToggle()
  ///     }
  /// ```
  ///
  /// A convenience over `floatingPanel(_:main:bar:toast:buttons:)` with `bar:`
  /// filled in; write your own bar there when these tabs do not suit.
  func floatingPanel<ID: Hashable, Main: View, ToastContent: View, Buttons: View>(
    _ controller: PanelController,
    tabs: [PanelTab<ID>],
    selection: Binding<ID>,
    @ViewBuilder main: @escaping (ID) -> Main,
    @ViewBuilder toast: @escaping () -> ToastContent = { EmptyView() },
    @ViewBuilder buttons: @escaping () -> Buttons = { EmptyView() }
  ) -> some View {
    floatingPanel(controller) {
      main(selection.wrappedValue)
    } bar: {
      PanelTabBar(tabs, selection: selection)
    } toast: {
      toast()
    } buttons: {
      buttons()
    }
  }
}
