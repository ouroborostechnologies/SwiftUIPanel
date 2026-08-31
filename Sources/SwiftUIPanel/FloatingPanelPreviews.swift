import SwiftUI

/// Stand-in full-bleed content with the panel attached, so every preview is
/// one line.
private struct PreviewHost: View {
  
  var configuration: Configuration = .default
  
  var taskbar: TemporaryTaskbarContent?
  
  @State private var selection = "a"

  var body: some View {
    LinearGradient(colors: [.teal, .green], startPoint: .top, endPoint: .bottom)
      .ignoresSafeArea()
      .floatingPanel(
        configuration: configuration,
        tabs: [
          FloatingPanelTab(id: "a", title: "A", systemImage: "a.circle"),
          FloatingPanelTab(id: "b", title: "B", systemImage: "b.circle"),
          FloatingPanelTab(id: "c", title: "C", systemImage: "c.circle")
        ],
        selection: $selection,
        taskbar: taskbar
      ) { tab in
        Text(tab).frame(maxWidth: .infinity, maxHeight: .infinity)
      }
  }
}

#Preview("Default") {
  PreviewHost()
}

#Preview("Bottom sheet") {
  PreviewHost(configuration: {
    var c = Configuration()
    c.layoutModeOverride = .bottomSheet
    return c
  }())
}

#Preview("Floating corner") {
  PreviewHost(configuration: {
    var c = Configuration()
    c.layoutModeOverride = .floatingCorner
    return c
  }())
}

#Preview("Taskbar") {
  PreviewHost(taskbar: TemporaryTaskbarContent(id: "measuring") {
    Label("Measuring — tap to add points", systemImage: "ruler")
      .padding(8)
  })
}
