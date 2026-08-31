import SwiftUI

/// The column of circular buttons top-right over the content, led by the
/// panel's show/hide toggle.
struct OverlayButtonStack: View {

  let style: PanelStyle
  let kinds: [OverlayButtonKind]
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
  private func button(for kind: OverlayButtonKind) -> some View {
    switch kind {
    case let .custom(_, systemImage, isActive, prominent, action):
      OverlayButton(style: style, systemImage: systemImage, label: systemImage,
                    isProminent: prominent, action: action)
        .symbolVariant(isActive ? .fill : .none)
    case let .menu(_, systemImage, prominent, content):
      Menu {
        content
      } label: {
        OverlayButtonLabel(style: style, systemImage: systemImage, isProminent: prominent)
      }
      .menuStyle(.button)
      .buttonStyle(.plain)
      .menuIndicator(.hidden)
      .fixedSize()
      .accessibilityLabel(systemImage)
    }
  }
}

/// The show/hide button. Lives at the top of the stack so there is one
/// container of controls, not two adjacent ones. Its glyph shows where the
/// panel actually is: a bottom sheet on iPhone, a leading panel elsewhere.
struct PanelVisibilityToggle: View {

  let style: PanelStyle
  @Binding var isPanelVisible: Bool

  @Environment(\.floatingPanelLayoutMode) private var layoutMode

  var body: some View {
    OverlayButton(style: style,
                  systemImage: layoutMode == .bottomSheet
                    ? "rectangle.bottomthird.inset.filled"
                    : "rectangle.leadingthird.inset.filled",
                  label: isPanelVisible ? "Hide panel" : "Show panel") {
      withAnimation(style.animation) { isPanelVisible.toggle() }
    }
    .opacity(isPanelVisible ? 1 : 0.6)
  }
}

struct OverlayButton: View {

  let style: PanelStyle
  let systemImage: String
  let label: String
  var isProminent: Bool = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      OverlayButtonLabel(style: style, systemImage: systemImage, isProminent: isProminent)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
  }
}

struct OverlayButtonLabel: View {

  let style: PanelStyle
  let systemImage: String
  var isProminent: Bool = false

  /// Tracks the user's type size, so the buttons grow with accessibility
  /// settings instead of staying pinned to points.
  @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1

  private var diameter: CGFloat {
    style.buttonDiameter * typeScale
  }

  var body: some View {
    Image(systemName: systemImage)
      .font(.body.weight(.medium))
      .imageScale(.medium)
      .foregroundStyle(isProminent ? AnyShapeStyle(.white) : AnyShapeStyle(Color.accentColor))
      .frame(width: diameter, height: diameter)
      .background {
        if isProminent {
          Circle().fill(Color.accentColor)
        } else {
          Circle().fill(style.buttonMaterial)
        }
      }
      .shadow(color: .black.opacity(style.shadowOpacity), radius: style.shadowRadius, y: style.shadowYOffset)
      .contentShape(Circle())
  }
}
