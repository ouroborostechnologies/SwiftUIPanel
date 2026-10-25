import SwiftUI
#if canImport(UIKit)
import UIKit

/// Reports which side of the window a landscape iPhone's sensor housing is on, in layout terms,
/// or nil when it is not on a side: portrait, or no window yet.
///
/// The safe area cannot say: it gives both sides the same inset. The housing is at the top of the
/// device, so the interface orientation places it — on the left when the interface is turned
/// `.landscapeRight`, on the right for `.landscapeLeft`.
struct SensorHousingReader: UIViewRepresentable {

  let onChange: (HorizontalEdge?) -> Void

  func makeUIView(context: Context) -> Probe {
    Probe(onChange: onChange)
  }

  func updateUIView(_ probe: Probe, context: Context) {
    probe.onChange = onChange
  }

  /// Fills the container, so a rotation resizes it and `layoutSubviews` reads the new side.
  final class Probe: UIView {

    var onChange: (HorizontalEdge?) -> Void
    private var reported: HorizontalEdge??

    init(onChange: @escaping (HorizontalEdge?) -> Void) {
      self.onChange = onChange
      super.init(frame: .zero)
      isUserInteractionEnabled = false
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
      let housing = Self.housing(in: window)
      guard reported != .some(housing) else { return }
      reported = housing
      // Out of the layout pass: the answer is SwiftUI state.
      DispatchQueue.main.async { [onChange] in onChange(housing) }
    }

    private static func housing(in window: UIWindow?) -> HorizontalEdge? {
      guard let window, let scene = window.windowScene else { return nil }
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
