//
//  File.swift
//  
//
//  Created by Connor Yass on 12/19/22.
//

import Foundation

public enum PanelSide {
    case left
    case right
}

public enum PanelDirection {
    case up
    case down
}

public struct PanelConfig {
    
    public init(minWidth: CGFloat = 240, idealWidth: CGFloat = 280, maxWidth: CGFloat = 320) {
        self.minWidth = minWidth
        self.idealWidth = idealWidth
        self.maxWidth = maxWidth
    }
    
    var minWidth: CGFloat
    var idealWidth: CGFloat
    var maxWidth: CGFloat
}

// MARK: -

public enum DragState {
    
    case inactive
    case dragging(translation: CGSize)
    case ended(translation: CGSize)
    
    public var translation: CGSize {
        switch self {
        case .inactive:
            return .zero
        case .dragging(let translation):
            return translation
        case .ended(let translation):
            return translation
        }
    }
    
    public var isDragging: Bool {
        switch self {
        case .inactive:
            return false
        case .dragging:
            return true
        case .ended:
            return false
        }
    }
}
