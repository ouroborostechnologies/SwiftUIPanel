import SwiftUI

public struct FloatingPanelConfiguration {

  public var style: FloatingChromeStyle = .default
  /// Forces a layout; `nil` resolves from the device idiom.
  public var layoutModeOverride: PanelLayoutMode? = nil
  /// Bottom-sheet resting heights. iPhone only.
  public var detents: [FloatingPanelDetent] = FloatingPanelDetent.defaultSet
  /// The sheet's detent at first appearance. Must be one of `detents`; the
  /// smallest is used otherwise.
  public var initialDetent: FloatingPanelDetent = .half
  /// Corner panel width at first appearance. iPad and Mac only.
  public var cornerPanelWidth: CGFloat = 340
  /// Corner panel width limits; the upper bound is further capped so the
  /// panel never reaches the button stack.
  public var cornerPanelWidthRange: ClosedRange<CGFloat> = 280 ... 520
  /// Corner panel height limits; the upper bound is further capped by the
  /// window.
  public var cornerPanelHeightRange: ClosedRange<CGFloat> = 160 ... 600
  /// Corner panel height at first appearance, clamped to the range.
  public var initialCornerPanelHeight: CGFloat = 420
  /// Whether a vertical resize of the corner panel snaps, on release, to the
  /// `detents` applied to its available height. Width always resizes freely.
  public var cornerPanelSnapsVertically: Bool = true
  public var showsMapOverlayButtons: Bool = true
  public var mapOverlayButtons: [MapOverlayButtonKind] = [.userLocation, .mapStyle]
  /// Whether the show/hide toggle leads the button stack.
  public var showsPanelVisibilityToggle: Bool = true

  public init() {}

  public static let `default` = FloatingPanelConfiguration()
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

/// A circular button over the map. The package renders chrome and reports
/// intent; it never owns location or map-style state.
public enum MapOverlayButtonKind: Identifiable {
  case userLocation
  case mapStyle
  case custom(id: String, systemImage: String, action: () -> Void)
  /// Beyond the spec: a button that opens a menu — the compact answer to
  /// "more buttons than a phone has room for".
  case menu(id: String, systemImage: String, content: AnyView)

  public var id: String {
    switch self {
    case .userLocation: "userLocation"
    case .mapStyle: "mapStyle"
    case let .custom(id, _, _): id
    case let .menu(id, _, _): id
    }
  }

  public static func menu<V: View>(id: String, systemImage: String, @ViewBuilder content: () -> V) -> MapOverlayButtonKind {
    .menu(id: id, systemImage: systemImage, content: AnyView(content()))
  }
}

/// Callbacks for the built-in buttons.
public struct FloatingPanelActions {
  public var onUserLocationTapped: () -> Void
  public var onMapStyleTapped: () -> Void
  /// Rendered filled while location following is on.
  public var isFollowingUserLocation: Bool

  public init(
    onUserLocationTapped: @escaping () -> Void = {},
    onMapStyleTapped: @escaping () -> Void = {},
    isFollowingUserLocation: Bool = false
  ) {
    self.onUserLocationTapped = onUserLocationTapped
    self.onMapStyleTapped = onMapStyleTapped
    self.isFollowingUserLocation = isFollowingUserLocation
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
