import SwiftUI

/// A transient surface in the panel's chrome: above the sheet on iPhone,
/// top-right on iPad and Mac. Sized to its content, never taller than it
/// needs to be.
struct TemporaryTaskbar: View {

  let style: FloatingChromeStyle
  let taskbar: TemporaryTaskbarContent

  var body: some View {
    taskbar.content
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .frame(minHeight: 44)
      .floatingChrome(style, corners: .all)
      .id(taskbar.id)
  }
}
