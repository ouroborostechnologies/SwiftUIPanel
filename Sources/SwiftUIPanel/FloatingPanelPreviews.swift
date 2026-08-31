import SwiftUI

/// The shell driven by the tab layer, at both layouts. The content underneath
/// reads `contentInsets` and centres itself in what the chrome leaves clear,
/// which is the fastest way to see whether the published geometry is honest.
private struct PanelPreview: View {

  let override: LayoutMode?

  @State private var controller = PanelController()
  @State private var section = "features"

  private let tabs = [
    PanelTab(id: "features", title: "Features", systemImage: "list.bullet"),
    PanelTab(id: "properties", title: "Properties", systemImage: "slider.horizontal.3"),
    PanelTab(id: "document", title: "Document", systemImage: "doc"),
  ]

  var body: some View {
    LinearGradient(colors: [.teal, .indigo], startPoint: .top, endPoint: .bottom)
      .overlay {
        Text("Clear space")
          .font(.title2)
          .padding(controller.contentInsets)
      }
      .floatingPanel(controller, tabs: tabs, selection: $section) { section in
        ScrollView {
          VStack(alignment: .leading, spacing: 8) {
            ForEach(0 ..< 20, id: \.self) { row in
              Text("\(section) \(row)")
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding()
        }
      } toast: {
        HStack(spacing: 16) {
          Text("Draw Polygon").font(.headline)
          Button { controller.isToastVisible = false } label: { Image(systemName: "checkmark") }
          Button { controller.isToastVisible = false } label: { Image(systemName: "xmark") }
        }
        .buttonStyle(.plain)
      } buttons: {
        PanelVisibilityToggle()
        Button { controller.isToastVisible.toggle() } label: { Image(systemName: "pencil.tip") }
        Button {} label: { Image(systemName: "plus") }
          .buttonStyle(PanelButtonStyle(prominent: true))
      }
      .onAppear { controller.layoutModeOverride = override }
  }
}

#Preview("Narrow") {
  PanelPreview(override: .bottomSheet)
}

#Preview("Wide") {
  PanelPreview(override: .floatingCorner)
}

#Preview("Resolved from width") {
  PanelPreview(override: nil)
}
