import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// The curvature of whatever the chrome floats in — the display on iOS and
/// iPadOS, the window on macOS — so a panel's corners can be concentric with it.
enum ContainerCornerRadius {

  /// The radius of a corner `inset` points inside the container, so the two
  /// curves share a centre. Never smaller than `fallback`, which is also the
  /// answer when the container's own radius is unknown.
  static func concentric(inset: CGFloat, fallback: CGFloat) -> CGFloat {
    container > 0 ? max(container - inset, fallback) : fallback
  }

  #if canImport(UIKit)
  /// Read once from a private `UIScreen` key, there being no public API. Zero
  /// — a square display, or the key going away — falls back to the style.
  static let container: CGFloat = {
    let key = ["_display", "Corner", "Radius"].joined()
    return (UIScreen.main.value(forKey: key) as? CGFloat) ?? 0
  }()
  #else
  /// AppKit exposes no window radius, so this tracks the system's window shape
  /// by eye, per major release.
  static let container: CGFloat = {
    if #available(macOS 26.0, *) { 26 } else { 11 }
  }()
  #endif
}
