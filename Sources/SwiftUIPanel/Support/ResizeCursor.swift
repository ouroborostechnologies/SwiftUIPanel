import SwiftUI

/// Tells a pointer user that an edge can be dragged.
///
/// - macOS 15 and later: the system's frame-resize arrows via `pointerStyle`.
/// - macOS 14: the equivalent `NSCursor` pushed on hover.
/// - iPadOS: iOS 17 exposes no resize-arrow pointer shape, so the pointer
///   snaps onto the grip instead (`hoverEffect`), which is the platform's own
///   cue for "this is draggable".
struct ResizeCursorModifier: ViewModifier {

  let edge: ResizeEdge

  func body(content: Content) -> some View {
    #if os(macOS)
    if #available(macOS 15, *) {
      content.pointerStyle(.frameResize(position: position, directions: .all))
    } else {
      content.onHover { hovering in
        if hovering { legacyCursor.push() } else { NSCursor.pop() }
      }
    }
    #else
    content.hoverEffect(.highlight)
    #endif
  }

  #if os(macOS)
  @available(macOS 15, *)
  private var position: FrameResizePosition {
    switch edge {
    case .trailing: .trailing
    case .bottom: .bottom
    case .bottomTrailing: .bottomTrailing
    }
  }

  /// macOS 14 ships no public diagonal resize cursor; the crosshair is the
  /// closest honest cue for the corner.
  private var legacyCursor: NSCursor {
    switch edge {
    case .trailing: .resizeLeftRight
    case .bottom: .resizeUpDown
    case .bottomTrailing: .crosshair
    }
  }
  #endif
}

extension View {
  func resizeCursor(_ edge: ResizeEdge) -> some View {
    modifier(ResizeCursorModifier(edge: edge))
  }
}
