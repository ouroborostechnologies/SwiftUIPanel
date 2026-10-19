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
          Button { drawing(false) } label: { Image(systemName: "checkmark") }
          Button { drawing(false) } label: { Image(systemName: "xmark") }
        }
        .buttonStyle(.plain)
      } panelAligned: {
        // Anchored to the panel's free edge — above the sheet on narrow, under
        // the panel on wide — and faded out once the panel fills the column.
        Text("Aligned with the panel")
          .font(.caption)
          .padding(8)
          .panelSurface(controller.style)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
      } panelTrailing: {
        PanelButtonStack {
          PanelVisibilityToggle()
          Button { drawing(!controller.isFocused) } label: { Image(systemName: "pencil.tip") }
          Button {} label: { Image(systemName: "plus") }
            .buttonStyle(PanelButtonStyle(prominent: true))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
      }
      .onAppear { controller.layoutModeOverride = override }
  }

  /// A task that takes the panel over: the toast names it, and the panel
  /// shrinks to its content with the tabs and the handle gone.
  private func drawing(_ isDrawing: Bool) {
    withAnimation(controller.style.animation) {
      controller.isToastVisible = isDrawing
      controller.isFocused = isDrawing
    }
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
