import SwiftUI

enum PlatformIdiom {

  /// The layout the current device wants, unless the consumer says otherwise.
  static func resolve(override: PanelLayoutMode?) -> PanelLayoutMode {
    if let override { return override }
    #if os(macOS)
    return .floatingCorner
    #else
    return UIDevice.current.userInterfaceIdiom == .phone ? .bottomSheet : .floatingCorner
    #endif
  }
}
