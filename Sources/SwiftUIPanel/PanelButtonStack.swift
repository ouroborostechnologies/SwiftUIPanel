import SwiftUI

/// A column of controls in the panel's chrome — the shape the top-trailing
/// stack of a map or an editor takes.
///
/// It spaces what it is given and makes `PanelButtonStyle` the default, so a
/// plain `Button` arrives dressed. It never inspects its content, and it
/// places itself nowhere: put it in one of the panel's containers and align it
/// there.
///
/// ```swift
/// .floatingPanel(panel) { … } bar: { … } panelTrailing: {
///     PanelButtonStack {
///         PanelVisibilityToggle()
///         Button { add() } label: { Image(systemName: "plus") }
///     }
///     .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
/// }
/// ```
public struct PanelButtonStack<Content: View>: View {

  private let content: Content

  @Environment(\.panelController) private var controller

  public init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  private var style: PanelStyle { controller?.style ?? .default }

  public var body: some View {
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
/// Every button inside a `PanelButtonStack` gets it by default. Apply it by
/// hand to dress a button elsewhere, or to make one prominent:
///
/// ```swift
/// Button { add() } label: { Image(systemName: "plus") }
///     .buttonStyle(PanelButtonStyle(prominent: true))
/// ```
///
/// A plain button draws its glyph in the primary label colour, the way the
/// system's own glass buttons do, and holds the style's appearance over any
/// backdrop (see `panelControlGlass(_:in:)`); a prominent one is filled and
/// draws it white.
/// Glass carries its own shadow and its own pressed response, so the style
/// adds neither.
public struct PanelButtonStyle: ButtonStyle {

  private let isProminent: Bool
  private let tint: Color?

  /// Grows the buttons with the user's type size rather than pinning them to
  /// points.
  @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1
  @Environment(\.panelController) private var controller
  /// See `PanelSurface`: read outside the glass so `.system` can re-assert it.
  @Environment(\.colorScheme) private var environmentScheme

  /// - Parameters:
  ///   - prominent: fills the glass with the accent colour, for the one primary
  ///     action of a screen, or for a mode while it is on.
  ///   - tint: the fill of a prominent button, in place of the accent colour.
  public init(prominent: Bool = false, tint: Color? = nil) {
    self.isProminent = prominent
    self.tint = tint
  }

  public func makeBody(configuration: Configuration) -> some View {
    let style = controller?.style ?? .default
    let diameter = style.buttonDiameter * typeScale
    let label = configuration.label
      .font(.body.weight(.medium))
      .imageScale(.medium)
      .frame(width: diameter, height: diameter)
    Group {
      if isProminent {
        // A tinted glass keeps its colour over any backdrop; only the plain
        // ones need pinning.
        label
          .foregroundStyle(.white)
          .glassEffect(style.buttonGlass.tint(tint ?? .accentColor).interactive(), in: .circle)
          .panelColorScheme(style.glassScheme, environment: environmentScheme)
      } else {
        label.panelControlGlass(style, in: .circle)
      }
    }
    .contentShape(Circle())
  }
}

/// A button that shows and hides the panel.
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
    }
  }
}
