import SwiftUI

enum PlatformIdiom {

  /// The layout a window wants: the consumer's override, else the width
  /// against the breakpoints. A zero width (not yet laid out) falls back to
  /// the device's natural mode so the first frame is not a sheet on a Mac.
  static func resolve(override: LayoutMode?, width: CGFloat, breakpoints: PanelLayoutBreakpoints) -> LayoutMode {
    if let override { return override }
    guard width > 0 else { return natural }
    return breakpoints.mode(for: width)
  }

  private static var natural: LayoutMode {
    #if os(macOS)
    return .floatingCorner
    #else
    return UIDevice.current.userInterfaceIdiom == .phone ? .bottomSheet : .floatingCorner
    #endif
  }
}
