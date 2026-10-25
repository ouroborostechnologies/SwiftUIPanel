import SwiftUI
#if canImport(UIKit)
import UIKit

/// What the window knows about the container the chrome floats in, and the safe area does not
/// say: how round its corners are, and which side a landscape iPhone's sensor housing is on.
struct ContainerReading: Equatable {
  /// The radius of the container's corners: the display's, for a window that fills it. Zero
  /// until the window has been read, and for a square container.
  var cornerRadius: CGFloat = 0
  /// The side the sensor housing is on, in layout terms, or nil when it is not on a side.
  var sensorHousing: HorizontalEdge?
}

/// Reads the container through a view placed in it.
///
/// The radius comes from UIKit's corner configuration: a view filling the container, given
/// container-concentric corners, takes the container's own radius at zero inset. The housing
/// comes from the interface orientation, since the safe area gives both sides the same inset;
/// it sits at the top of the device, so it is on the left when the interface is turned
/// `.landscapeRight` and on the right for `.landscapeLeft`.
struct ContainerReader: UIViewRepresentable {

  let onChange: (ContainerReading) -> Void

  func makeUIView(context: Context) -> Probe {
    Probe(onChange: onChange)
  }

  func updateUIView(_ probe: Probe, context: Context) {
    probe.onChange = onChange
  }

  /// Fills the container, so a rotation or a resize lays it out again and it reads afresh.
  final class Probe: UIView {

    var onChange: (ContainerReading) -> Void
    private var reported: ContainerReading?

    init(onChange: @escaping (ContainerReading) -> Void) {
      self.onChange = onChange
      super.init(frame: .zero)
      isUserInteractionEnabled = false
      cornerConfiguration = .corners(radius: .containerConcentric())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMoveToWindow() {
      super.didMoveToWindow()
      report()
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      report()
    }

    private func report() {
      guard let window else { return }
      // Read during layout, so UIKit lays the probe out again if the radius changes.
      let reading = ContainerReading(cornerRadius: effectiveRadius(corner: .topLeft),
                                     sensorHousing: Self.housing(in: window))
      guard reading != reported else { return }
      reported = reading
      // Out of the layout pass: the answer is SwiftUI state.
      DispatchQueue.main.async { [onChange] in onChange(reading) }
    }

    private static func housing(in window: UIWindow) -> HorizontalEdge? {
      guard let scene = window.windowScene else { return nil }
      let isLeftToRight = window.effectiveUserInterfaceLayoutDirection == .leftToRight
      switch scene.effectiveGeometry.interfaceOrientation {
      case .landscapeRight: return isLeftToRight ? .leading : .trailing
      case .landscapeLeft: return isLeftToRight ? .trailing : .leading
      default: return nil
      }
    }
  }
}
#endif
