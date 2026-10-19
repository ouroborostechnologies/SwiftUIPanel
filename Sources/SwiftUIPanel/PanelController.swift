import SwiftUI

/// The state of one panel: what it shows, how it is sized, and what its chrome
/// covers.
///
/// Hold one per screen and hand it to
/// `View.floatingPanel(_:main:bar:toast:panelAligned:panelTrailing:)`.
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
  /// Whether a sheet rises to its largest detent while a docked keyboard is
  /// up, and returns to the detent it left once the keyboard goes. A sheet
  /// dragged elsewhere meanwhile stays where it was dragged. A floating or
  /// hardware keyboard covers nothing and raises nothing, and the wide layout
  /// never rises.
  public var expandsForKeyboard: Bool = true
  /// Gives the panel over to its main slot, for a task whose controls are
  /// all the panel should show — drawing on the content behind it, say.
  ///
  /// The bar slot and the resize handle go, and the panel takes the height
  /// its main slot's content asks for instead of a detent: capped by the room
  /// available, following the content as it grows and shrinks, and never
  /// snapping. The wide panel's width stays resizable.
  ///
  /// `detent` is left alone, so clearing this puts the panel back where it
  /// rested. Animate the change as you would a detent's.
  public var isFocused: Bool = false
  /// Every number and material the chrome draws with.
  public var style: PanelStyle = .default
  /// Forces a layout. `nil` resolves it from the container's width.
  public var layoutModeOverride: LayoutMode? = nil

  // MARK: What the panel reports

  /// The layout the container's width resolved to.
  public private(set) var layoutMode: LayoutMode = .floatingCorner
  /// What the panel covers, per edge. Unused edges are zero, and a hidden
  /// panel contributes nothing. The toast and the two free-space containers float
  /// over the content rather than displacing it, so none of them shows up
  /// here.
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
  /// The frame of the container handed to `panelAligned:`. See `panelFrame`.
  public private(set) var panelAlignedFrame: CGRect = .zero
  /// The frame of the container handed to `panelTrailing:`. See `panelFrame`.
  public private(set) var panelTrailingFrame: CGRect = .zero
  /// How visible chrome over the panel's free space should be: 1, falling to
  /// 0 as a bottom sheet on iOS closes the last stretch to `.full` — the same
  /// stretch its margins dissolve and the scrim rises across. Everywhere else
  /// it stays 1: a wide panel at `.full` leaves the space beside it alone.
  ///
  /// It tracks an interactive drag, so chrome fades out as the sheet is
  /// dragged open and back in as it is dragged down. The package applies it
  /// to `panelAligned:` and `panelTrailing:`; apply it to anything of your own
  /// drawn over the content.
  ///
  /// ```swift
  /// Crosshair()
  ///     .opacity(panel.freeSpaceOpacity)
  /// ```
  public private(set) var freeSpaceOpacity: Double = 1

  public init() {}

  /// Adopts one layout pass's geometry. Called from outside the view update.
  func report(_ geometry: ChromeGeometry) {
    layoutMode = geometry.layoutMode
    contentInsets = geometry.contentInsets
    panelFrame = geometry.panelFrame
    toastFrame = geometry.toastFrame
    panelAlignedFrame = geometry.panelAlignedFrame
    panelTrailingFrame = geometry.panelTrailingFrame
    freeSpaceOpacity = geometry.freeSpaceOpacity
  }
}

/// The part of a layout pass the controller publishes, gathered so the engine
/// writes it in one go and can tell when nothing changed.
struct ChromeGeometry: Equatable {
  var layoutMode: LayoutMode
  var contentInsets: EdgeInsets
  var panelFrame: CGRect
  var toastFrame: CGRect
  var panelAlignedFrame: CGRect
  var panelTrailingFrame: CGRect
  var freeSpaceOpacity: Double
}

private struct PanelControllerKey: EnvironmentKey {
  static let defaultValue: PanelController? = nil
}

public extension EnvironmentValues {
  /// The controller driving the chrome this view sits in, if any. Set by
  /// `View.floatingPanel(_:main:bar:toast:panelAligned:panelTrailing:)`.
  internal(set) var panelController: PanelController? {
    get { self[PanelControllerKey.self] }
    set { self[PanelControllerKey.self] = newValue }
  }
}
