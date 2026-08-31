import SwiftUI

/// The column of controls at the container's top-trailing corner.
///
/// It spaces what it is given and makes `PanelButtonStyle` the default, so a
/// plain `Button` arrives dressed. It never inspects its content.
struct ButtonStack<Content: View>: View {

  let style: PanelStyle
  @ViewBuilder let content: Content

  var body: some View {
    VStack(spacing: style.buttonSpacing) {
      content
    }
    .buttonStyle(PanelButtonStyle())
  }
}

/// The circular material treatment the panel's buttons share.
///
/// Every button in the `buttons:` slot gets it by default. Apply it by hand to
/// dress a button elsewhere, or to make one prominent:
///
/// ```swift
/// Button { add() } label: { Image(systemName: "plus") }
///     .buttonStyle(PanelButtonStyle(prominent: true))
/// ```
public struct PanelButtonStyle: ButtonStyle {

  private let isProminent: Bool

  /// Grows the buttons with the user's type size rather than pinning them to
  /// points.
  @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1
  @Environment(\.panelController) private var controller

  /// - Parameter prominent: fills the circle with the accent colour, for the
  ///   one primary action of a screen.
  public init(prominent: Bool = false) {
    self.isProminent = prominent
  }

  public func makeBody(configuration: Configuration) -> some View {
    let style = controller?.style ?? .default
    let diameter = style.buttonDiameter * typeScale
    configuration.label
      .font(.body.weight(.medium))
      .imageScale(.medium)
      .foregroundStyle(isProminent ? AnyShapeStyle(.white) : AnyShapeStyle(Color.accentColor))
      .frame(width: diameter, height: diameter)
      .background(Circle().fill(isProminent ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(style.buttonMaterial)))
      .shadow(color: .black.opacity(style.shadowOpacity), radius: style.shadowRadius, y: style.shadowYOffset)
      .contentShape(Circle())
      .opacity(configuration.isPressed ? style.dimmedOpacity : 1)
  }
}

/// A button that shows and hides the panel, for the `buttons:` slot.
///
/// Optional and free-standing: place it where it belongs, or leave it out. Its
/// glyph follows the panel to whichever edge the current layout anchors it to.
public struct PanelVisibilityToggle: View {

  @Environment(\.panelController) private var controller

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
      .accessibilityLabel(controller.isPanelVisible ? "Hide panel" : "Show panel")
      .opacity(controller.isPanelVisible ? 1 : controller.style.dimmedOpacity)
    }
  }
}
