import SwiftUI

/// The state of one panel: what it shows, how it is sized, and what its chrome
/// covers.
///
/// Hold one per screen and hand it to `View.floatingPanel(_:main:bar:toast:buttons:)`.
/// Set the properties above the divider to drive the chrome from anywhere in
/// your view tree; read the ones below it to lay content out around what the
/// chrome covers.
///
/// ```swift
/// @State private var panel = PanelController()
///
/// MyContent()
///     .floatingPanel(panel) { … } bar: { … }
/// ```
@Observable
public final class PanelController {

  // MARK: What you set

  /// Whether the panel is on screen. Changing it slides the panel off the
  /// container edge it is anchored to, and back.
  public var isPanelVisible: Bool = true
  /// Whether the toast is on screen. It has no timer and never dismisses
  /// itself.
  public var isToastVisible: Bool = false
  /// The panel's resting height. Its value when the controller is created is
  /// the initial detent; a value outside `detents` resolves to the smallest.
  public var detent: Detent = .half
  /// The resting heights the panel snaps between.
  public var detents: [Detent] = Detent.defaultSet
  /// Every number and material the chrome draws with.
  public var style: PanelStyle = .default
  /// Forces a layout. `nil` resolves it from the container's width.
  public var layoutModeOverride: LayoutMode? = nil

  // MARK: What the panel reports

  /// The layout the container's width resolved to.
  public private(set) var layoutMode: LayoutMode = .floatingCorner
  /// What the chrome covers, per edge — the union of every visible surface.
  /// Unused edges are zero, and a hidden surface contributes nothing.
  ///
  /// It tracks an interactive drag continuously, so content follows the moving
  /// edge instead of jumping when the drag ends.
  ///
  /// ```swift
  /// Text("Centred in the clear space")
  ///     .padding(panel.contentInsets)
  /// ```
  public private(set) var contentInsets: EdgeInsets = EdgeInsets()
  /// The panel's frame in the content's coordinate space, for bridging into an
  /// inset API that wants a rect. Prefer `contentInsets`.
  public private(set) var panelFrame: CGRect = .zero
  /// The toast's frame. See `panelFrame`.
  public private(set) var toastFrame: CGRect = .zero
  /// The button stack's frame. See `panelFrame`.
  public private(set) var buttonStackFrame: CGRect = .zero

  public init() {}

  /// Adopts one layout pass's geometry. Called from outside the view update.
  func report(_ geometry: ChromeGeometry) {
    layoutMode = geometry.layoutMode
    contentInsets = geometry.contentInsets
    panelFrame = geometry.panelFrame
    toastFrame = geometry.toastFrame
    buttonStackFrame = geometry.buttonStackFrame
  }
}

/// The part of a layout pass the controller publishes, gathered so the engine
/// writes it in one go and can tell when nothing changed.
struct ChromeGeometry: Equatable {
  var layoutMode: LayoutMode
  var contentInsets: EdgeInsets
  var panelFrame: CGRect
  var toastFrame: CGRect
  var buttonStackFrame: CGRect
}

private struct PanelControllerKey: EnvironmentKey {
  static let defaultValue: PanelController? = nil
}

public extension EnvironmentValues {
  /// The controller driving the chrome this view sits in, if any. Set by
  /// `View.floatingPanel(_:main:bar:toast:buttons:)`.
  internal(set) var panelController: PanelController? {
    get { self[PanelControllerKey.self] }
    set { self[PanelControllerKey.self] = newValue }
  }
}
