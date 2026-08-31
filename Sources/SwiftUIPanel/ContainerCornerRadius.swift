import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// The corner radius of the container the chrome lives in — the physical
/// display on iOS and iPadOS, the window on macOS — so panel corners can be
/// concentric with the container's own curvature.
enum ContainerCornerRadius {

  #if canImport(UIKit)
  /// The display's corner radius, read once. There is no public API; the
  /// value is a private `UIScreen` key, and `0` (square display, or the key
  /// disappearing) makes callers fall back to the style's own radius.
  static let current: CGFloat = {
    let key = ["_display", "Corner", "Radius"].joined()
    return (UIScreen.main.value(forKey: key) as? CGFloat) ?? 0
  }()
  #else
  /// Standard window corner radius. Not public API either; matched to the
  /// system's window shape by eye per major release.
  static let current: CGFloat = {
    if #available(macOS 26.0, *) { return 26 } else { return 11 }
  }()
  #endif

  /// The radius of a corner `inset` points inside the container, so the two
  /// curves share a center. Floored at `fallback` — which is also the answer
  /// when the container's radius is unknown.
  static func concentric(inset: CGFloat, fallback: CGFloat) -> CGFloat {
    current > 0 ? max(current - inset, fallback) : fallback
  }
}
