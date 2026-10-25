import SwiftUI

/// The curvature of whatever the chrome floats in — the display on iOS and
/// iPadOS, the window on macOS — so a panel's corners can be concentric with it.
enum ContainerCornerRadius {

  /// The radius of a corner `inset` points inside a container whose own corners have
  /// `container`, so the two curves share a centre. Never smaller than `fallback`, which is also
  /// the answer when the container's radius is unknown.
  static func concentric(inset: CGFloat, in container: CGFloat, fallback: CGFloat) -> CGFloat {
    container > 0 ? max(container - inset, fallback) : fallback
  }

  #if !canImport(UIKit)
  /// AppKit exposes no window radius, so this tracks the system's window shape
  /// by eye, per major release. UIKit reads its container's; see `ContainerReader`.
  static let window: CGFloat = {
    if #available(macOS 26.0, *) { 26 } else { 11 }
  }()
  #endif
}
