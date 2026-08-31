import SwiftUI

extension View {
  /// Tells a pointer user that this edge can be dragged.
  func resizeCursor(_ edge: ResizeEdge) -> some View {
    modifier(ResizeCursor(edge: edge))
  }
}

/// The pointer cue for a resize grip, in whatever form the platform offers:
/// the system's frame-resize arrows on macOS 15, the matching `NSCursor` on
/// macOS 14, and — iOS exposing no resize-arrow shape — a pointer that snaps
/// onto the grip on iPadOS.
private struct ResizeCursor: ViewModifier {

  let edge: ResizeEdge

  func body(content: Content) -> some View {
    #if os(macOS)
    if #available(macOS 15, *) {
      content.pointerStyle(.frameResize(position: framePosition, directions: .all))
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
  private var framePosition: FrameResizePosition {
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
