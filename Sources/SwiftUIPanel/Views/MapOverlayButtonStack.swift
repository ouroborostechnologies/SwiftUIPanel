import SwiftUI

/// The column of circular buttons top-right over the map, led by the panel's
/// show/hide toggle.
struct MapOverlayButtonStack: View {

  let style: FloatingChromeStyle
  let kinds: [MapOverlayButtonKind]
  let actions: FloatingPanelActions
  let showsVisibilityToggle: Bool
  @Binding var isPanelVisible: Bool

  var body: some View {
    VStack(spacing: 8) {
      if showsVisibilityToggle {
        PanelVisibilityToggle(style: style, isPanelVisible: $isPanelVisible)
      }
      ForEach(kinds) { kind in
        button(for: kind)
      }
    }
  }

  @ViewBuilder
  private func button(for kind: MapOverlayButtonKind) -> some View {
    switch kind {
    case .userLocation:
      MapOverlayButton(style: style,
                       systemImage: actions.isFollowingUserLocation ? "location.fill" : "location",
                       label: "Current location",
                       action: actions.onUserLocationTapped)
    case .mapStyle:
      MapOverlayButton(style: style, systemImage: "map", label: "Map style", action: actions.onMapStyleTapped)
    case let .custom(_, systemImage, action):
      MapOverlayButton(style: style, systemImage: systemImage, label: systemImage, action: action)
    case let .menu(_, systemImage, content):
      Menu {
        content
      } label: {
        MapOverlayButtonLabel(style: style, systemImage: systemImage)
      }
      .menuStyle(.borderlessButton)
      .menuIndicator(.hidden)
      .fixedSize()
      .accessibilityLabel(systemImage)
    }
  }
}

/// The show/hide button. Lives at the top of the stack so there is one
/// container of controls, not two adjacent ones.
struct PanelVisibilityToggle: View {

  let style: FloatingChromeStyle
  @Binding var isPanelVisible: Bool

  var body: some View {
    MapOverlayButton(style: style,
                     systemImage: isPanelVisible ? "sidebar.leading" : "sidebar.leading",
                     label: isPanelVisible ? "Hide panel" : "Show panel") {
      withAnimation(style.animation) { isPanelVisible.toggle() }
    }
    .symbolVariant(isPanelVisible ? .fill : .none)
  }
}

struct MapOverlayButton: View {

  let style: FloatingChromeStyle
  let systemImage: String
  let label: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      MapOverlayButtonLabel(style: style, systemImage: systemImage)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
  }
}

struct MapOverlayButtonLabel: View {

  let style: FloatingChromeStyle
  let systemImage: String

  var body: some View {
    Image(systemName: systemImage)
      .font(.system(size: 18, weight: .medium))
      .foregroundStyle(Color.accentColor)
      .frame(width: style.buttonDiameter, height: style.buttonDiameter)
      .background(style.buttonMaterial, in: Circle())
      .shadow(color: .black.opacity(style.shadowOpacity), radius: style.shadowRadius, y: style.shadowYOffset)
      .contentShape(Circle())
  }
}
