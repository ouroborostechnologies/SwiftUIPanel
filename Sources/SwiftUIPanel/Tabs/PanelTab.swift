import SwiftUI

/// One tab of the panel's bar slot: an icon, a label, and the value it selects.
public struct PanelTab<ID: Hashable>: Identifiable, Hashable {

  public let id: ID
  /// The label under the icon. Looked up in the app's string catalogue when
  /// it is drawn, so a title given here in English localizes with everything
  /// else and the package carries no resources of its own.
  public let title: String
  public let systemImage: String

  public init(id: ID, title: String, systemImage: String) {
    self.id = id
    self.title = title
    self.systemImage = systemImage
  }
}
