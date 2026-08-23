import SwiftUI

/// The part of the content the panel currently covers.
///
/// On iPhone a bottom inset that tracks the sheet live, mid-drag included;
/// on iPad and Mac a leading inset for the corner panel's column. Unused
/// edges are zero, so a consumer reads one value and never branches on
/// platform.
public struct FloatingPanelInsetsKey: EnvironmentKey {
  public static let defaultValue: EdgeInsets = EdgeInsets()
}

public extension EnvironmentValues {
  var floatingPanelInsets: EdgeInsets {
    get { self[FloatingPanelInsetsKey.self] }
    set { self[FloatingPanelInsetsKey.self] = newValue }
  }
}

/// The panel's frame in the content's coordinate space — the escape hatch for
/// bridging into non-SwiftUI inset APIs. Most consumers only need the
/// environment value above.
public struct FloatingPanelGeometryKey: PreferenceKey {
  public static var defaultValue: CGRect = .zero
  public static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}
