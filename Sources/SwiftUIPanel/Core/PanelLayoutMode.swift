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
  /// Regular: one panel anchored top-left, resizable, one at a time.
  case floatingCorner
  /// Wide: the primary panel top-left and a secondary panel top-right, both
  /// open, the content full-bleed beneath.
  case dualCorner

  /// Whether panels float rather than sheet.
  public var panelsFloat: Bool { self != .bottomSheet }
  public var showsSecondaryPanel: Bool { self == .dualCorner }

  /// The mode a window of `width` points gets. Public so a consumer can make
  /// the same decision — which tabs to offer where — from the same rule.
  public static func resolve(width: CGFloat, configuration: FloatingPanelConfiguration) -> PanelLayoutMode {
    PlatformIdiom.resolve(override: configuration.layoutModeOverride, width: width, breakpoints: configuration.layoutBreakpoints)
  }
}

/// The widths at which the presentation changes.
public struct PanelLayoutBreakpoints: Sendable, Hashable {
  /// Below this, panels become a bottom sheet. An iPhone in landscape clears
  /// it; portrait does not.
  public var narrowestFloatingWidth: CGFloat
  /// Below this, one floating panel; at or above, both. Roughly an iPad with
  /// room for panels on both sides of the content.
  public var narrowestDualWidth: CGFloat

  public init(narrowestFloatingWidth: CGFloat = 700, narrowestDualWidth: CGFloat = 1080) {
    self.narrowestFloatingWidth = narrowestFloatingWidth
    self.narrowestDualWidth = narrowestDualWidth
  }

  public static let `default` = PanelLayoutBreakpoints()

  func mode(for width: CGFloat) -> PanelLayoutMode {
    switch width {
    case ..<narrowestFloatingWidth: .bottomSheet
    case ..<narrowestDualWidth: .floatingCorner
    default: .dualCorner
    }
  }
}
