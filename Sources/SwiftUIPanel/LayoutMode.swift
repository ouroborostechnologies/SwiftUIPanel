import SwiftUI

/// How the panel is presented at the container's current width.
public enum LayoutMode: Sendable, Hashable {
  /// Narrow: the panel is a bottom-anchored sheet.
  case bottomSheet
  /// Wide: the panel floats top-leading.
  case floatingCorner

  /// The mode a container of `width` points gets.
  ///
  /// Public so you can make the same call the package does — which sections to
  /// offer where, say — from the same rule.
  public static func resolve(width: CGFloat, style: PanelStyle) -> LayoutMode {
    width < style.narrowestFloatingWidth ? .bottomSheet : .floatingCorner
  }
}
