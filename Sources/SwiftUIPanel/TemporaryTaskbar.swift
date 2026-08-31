import SwiftUI

/// A transient surface in the panel's chrome: above the sheet on iPhone,
/// where it matches the sheet's width; top centre on iPad and Mac, where the
/// shell gives it a width. Never taller than its content needs.
struct TemporaryTaskbar: View {

  let style: PanelStyle
  let taskbar: TemporaryTaskbarContent

  var body: some View {
    taskbar.content
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .frame(minHeight: 44)
      .floatingChrome(style)
      .id(taskbar.id)
  }
}
