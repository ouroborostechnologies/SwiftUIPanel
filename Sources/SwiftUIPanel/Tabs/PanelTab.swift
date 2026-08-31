import SwiftUI

/// One tab of the panel's bar slot: an icon, a label, and the value it selects.
public struct PanelTab<ID: Hashable>: Identifiable, Hashable {

  public let id: ID
  public let title: String
  public let systemImage: String

  public init(id: ID, title: String, systemImage: String) {
    self.id = id
    self.title = title
    self.systemImage = systemImage
  }
}
