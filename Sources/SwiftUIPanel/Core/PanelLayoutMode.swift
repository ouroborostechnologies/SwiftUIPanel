/// How the panel is presented.
///
/// Resolved from the device idiom, not the size class: an iPad in split view
/// is "compact" but still wants the corner panel, not the phone sheet.
public enum PanelLayoutMode: Sendable {
  /// iPhone: a sheet anchored to the bottom edge with detents.
  case bottomSheet
  /// iPad and Mac: an inspector anchored top-left, resizable vertically.
  case floatingCorner
}
