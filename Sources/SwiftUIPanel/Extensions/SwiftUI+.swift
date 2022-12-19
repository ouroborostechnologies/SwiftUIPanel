//
//  SwiftUI+.swift
//  Cartographer
//
//  Created by Connor Yass on 12/10/22.
//

import SwiftUI

extension View {
    
    /// Clips the view to a rounded rectangle with the given corner radius, border width, and style
    ///
    public func roundedBorder<S>(_ content: S,
                                 width: CGFloat = 1,
                                 cornerRadius: CGFloat,
                                 cornerStyle: RoundedCornerStyle = .circular) -> some View where S : ShapeStyle
    {
        let roundedRect = RoundedRectangle(cornerRadius: cornerRadius, style: cornerStyle)
        return clipShape(roundedRect).overlay(roundedRect.strokeBorder(content, lineWidth: width))
    }
}


extension Animation {
    
    public static let customSpring: Animation = .interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0)
}
