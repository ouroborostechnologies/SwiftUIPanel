//
//  File.swift
//  
//
//  Created by Connor Yass on 3/30/24.
//

import SwiftUI

extension View {
  
  @ViewBuilder
  func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
    if conditional {
      content(self)
    } else {
      self
    }
  }
}
