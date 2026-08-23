import SwiftUI

/// How the panel is presented.
///
/// Resolved from the window's width, so one view hierarchy serves a phone, a
/// narrow iPad window, and a wide Mac window, and changes only its panel
/// presentation as the window is resized. The consumer can still force a
/// mode through the configuration.
public enum PanelLayoutMode: Sendable, Hashable {
  /// Narrow: a sheet anchored to the bottom edge with detents.
  case bottomSheet
  /// Regular and wide: one panel anchored top-left, resizable.
  case floatingCorner

  /// Whether the panel floats rather than sheets.
  public var panelsFloat: Bool { self != .bottomSheet }

  /// The mode a window of `width` points gets. Public so a consumer can make
  /// the same decision — which tabs to offer where — from the same rule.
  public static func resolve(width: CGFloat, configuration: FloatingPanelConfiguration) -> PanelLayoutMode {
    PlatformIdiom.resolve(override: configuration.layoutModeOverride, width: width, breakpoints: configuration.layoutBreakpoints)
  }
}

/// The width at which the presentation changes.
public struct PanelLayoutBreakpoints: Sendable, Hashable {
  /// Below this, the panel becomes a bottom sheet. An iPhone in landscape
  /// clears it; portrait does not.
  public var narrowestFloatingWidth: CGFloat

  public init(narrowestFloatingWidth: CGFloat = 700) {
    self.narrowestFloatingWidth = narrowestFloatingWidth
  }

  public static let `default` = PanelLayoutBreakpoints()

  func mode(for width: CGFloat) -> PanelLayoutMode {
    width < narrowestFloatingWidth ? .bottomSheet : .floatingCorner
  }
}
