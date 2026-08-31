import SwiftUI

public struct Configuration {

  public var style: PanelStyle = .default
  /// Forces a layout; `nil` resolves from the window width.
  public var layoutModeOverride: LayoutMode? = nil
  /// The widths at which the presentation changes.
  public var layoutBreakpoints: PanelLayoutBreakpoints = .default
  /// Bottom-sheet resting heights. iPhone only.
  public var detents: [Detent] = Detent.defaultSet
  /// The sheet's detent at first appearance. Must be one of `detents`; the
  /// smallest is used otherwise.
  public var initialDetent: Detent = .half
  /// Corner panel width at first appearance. iPad and Mac only.
  public var cornerPanelWidth: CGFloat = 340
  /// Corner panel width limits; the upper bound is further capped so the
  /// panel never reaches the button stack.
  public var cornerPanelWidthRange: ClosedRange<CGFloat> = 280 ... 520
  /// Corner panel height limits; the upper bound is further capped by the window.
  public var cornerPanelHeightRange: ClosedRange<CGFloat> = 160 ... 600
  /// Corner panel height at first appearance, clamped to the range.
  public var initialCornerPanelHeight: CGFloat = 420
  /// The taskbar's width at the top of the window. iPad and Mac only, and
  /// capped by the room left between the panel and the button stack.
  public var taskbarWidth: CGFloat = 560
  /// Whether a vertical resize of the corner panel snaps, on release, to the
  /// `detents` applied to its available height. Width always resizes freely.
  public var cornerPanelSnapsVertically: Bool = true
  public var showsOverlayButtons: Bool = true
  public var overlayButtons: [OverlayButtonKind] = []
  /// Whether the show/hide toggle leads the button stack.
  public var showsPanelVisibilityToggle: Bool = true

  public init() {}

  public static let `default` = Configuration()
}

/// One tab of the panel. Ships with a `String` id for simplicity.
public struct FloatingPanelTab: Identifiable, Equatable, Hashable, Sendable {
  public let id: String
  public let title: String
  public let systemImage: String

  public init(id: String, title: String, systemImage: String) {
    self.id = id
    self.title = title
    self.systemImage = systemImage
  }
}

/// A circular button floating over the content. The package renders chrome
/// and reports intent; what a button means belongs to the consumer.
///
/// A `prominent` button is filled with the accent color — for the one
/// primary action of the screen.
public enum OverlayButtonKind: Identifiable {
  /// `isActive` renders the symbol filled — for a mode that is currently on.
  case custom(id: String, systemImage: String, isActive: Bool, prominent: Bool, action: () -> Void)
  /// A button that opens a menu — the compact answer to "more buttons than
  /// a phone has room for".
  case menu(id: String, systemImage: String, prominent: Bool, content: AnyView)

  public var id: String {
    switch self {
    case let .custom(id, _, _, _, _): id
    case let .menu(id, _, _, _): id
    }
  }

  public static func custom(id: String, systemImage: String, action: @escaping () -> Void) -> OverlayButtonKind {
    .custom(id: id, systemImage: systemImage, isActive: false, prominent: false, action: action)
  }

  public static func custom(id: String, systemImage: String, isActive: Bool,
                            action: @escaping () -> Void) -> OverlayButtonKind {
    .custom(id: id, systemImage: systemImage, isActive: isActive, prominent: false, action: action)
  }

  public static func menu<V: View>(id: String, systemImage: String, prominent: Bool = false,
                                   @ViewBuilder content: () -> V) -> OverlayButtonKind {
    .menu(id: id, systemImage: systemImage, prominent: prominent, content: AnyView(content()))
  }
}

/// Something transient shown in the taskbar. Presence drives presentation.
public struct TemporaryTaskbarContent: Identifiable {
  public let id: String
  public var content: AnyView

  public init<V: View>(id: String, @ViewBuilder content: () -> V) {
    self.id = id
    self.content = AnyView(content())
  }
}
