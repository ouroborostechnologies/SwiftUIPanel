import SwiftUI

/// The column of controls at the container's top-trailing corner.
///
/// It spaces what it is given and makes `PanelButtonStyle` the default, so a
/// plain `Button` arrives dressed. It never inspects its content.
struct ButtonStack<Content: View>: View {

  let style: PanelStyle
  @ViewBuilder let content: Content

  var body: some View {
    // One container: the buttons' glass samples and blends as a single piece
    // of material rather than as a column of unrelated lenses.
    GlassEffectContainer(spacing: style.buttonSpacing) {
      VStack(spacing: style.buttonSpacing) {
        content
      }
    }
    .buttonStyle(PanelButtonStyle())
  }
}

/// The circular glass treatment the panel's buttons share.
///
/// Every button in the `buttons:` slot gets it by default. Apply it by hand to
/// dress a button elsewhere, or to make one prominent:
///
/// ```swift
/// Button { add() } label: { Image(systemName: "plus") }
///     .buttonStyle(PanelButtonStyle(prominent: true))
/// ```
///
/// Glass carries its own shadow and its own pressed response, so the style
/// adds neither.
public struct PanelButtonStyle: ButtonStyle {

  private let isProminent: Bool

  /// Grows the buttons with the user's type size rather than pinning them to
  /// points.
  @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1
  @Environment(\.panelController) private var controller
  /// See `PanelSurface`: read outside the glass so `.system` can re-assert it.
  @Environment(\.colorScheme) private var environmentScheme

  /// - Parameter prominent: tints the glass with the accent colour, for the
  ///   one primary action of a screen.
  public init(prominent: Bool = false) {
    self.isProminent = prominent
  }

  public func makeBody(configuration: Configuration) -> some View {
    let style = controller?.style ?? .default
    let diameter = style.buttonDiameter * typeScale
    let glass = isProminent ? style.buttonGlass.tint(.accentColor) : style.buttonGlass
    configuration.label
      .font(.body.weight(.medium))
      .imageScale(.medium)
      .foregroundStyle(isProminent ? AnyShapeStyle(.white) : AnyShapeStyle(Color.accentColor))
      .frame(width: diameter, height: diameter)
      .glassEffect(glass.interactive(), in: .circle)
      .panelColorScheme(style.glassScheme, environment: environmentScheme)
      .contentShape(Circle())
  }
}

/// A button that shows and hides the panel, for the `buttons:` slot.
///
/// Optional and free-standing: place it where it belongs, or leave it out. Its
/// glyph follows the panel to whichever edge the current layout anchors it to.
public struct PanelVisibilityToggle: View {

  @Environment(\.panelController) private var controller
  /// See `PanelSurface`: read outside the glass so `.system` can re-assert it.
  @Environment(\.colorScheme) private var environmentScheme

  public init() {}

  public var body: some View {
    if let controller {
      Button {
        controller.isPanelVisible.toggle()
      } label: {
        Image(systemName: controller.layoutMode == .bottomSheet
              ? "rectangle.bottomthird.inset.filled"
              : "rectangle.leadingthird.inset.filled")
      }
      .accessibilityLabel(controller.isPanelVisible ? "Hide Panel" : "Show Panel")
      .opacity(controller.isPanelVisible ? 1 : controller.style.dimmedOpacity)
    }
  }
}
