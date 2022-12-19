//
//  SwiftUIView.swift
//  
//
//  Created by Connor Yass on 12/19/22.
//

import SwiftUI

/// A vertically resizable card with rounded corners
///
public struct Panel<Content: View>: View {
    
    @GestureState private var dragState = DragState.inactive
    
    /// The percentage of the panel's container height that it is taking up (1.0 = fully open, 0.0 = completely closed)
    @Binding public var heightFactor: CGFloat
    
    /// The direction in which the panel can expand
    public var expandDirection: PanelDirection
    
    @ViewBuilder public var content: () -> Content
    
    public var body: some View {
        GeometryReader { geometry in
            
            let container = geometry.frame(in: .local)
            
            let panelHeight = container.height * heightFactor + dragState.translation.height * ((expandDirection == .up) ? -1 : 1)
            let panelWidth = container.width
            
            let panelX = panelWidth / 2.0
            let panelY = (expandDirection == .down) ? (panelHeight / 2.0) : container.height - (panelHeight / 2.0)
            
            makeContent()
                .frame(width: panelWidth, height: panelHeight)
                .position(x: panelX, y: panelY)
                .gesture(makeGesture(for: container))
        }
    }
    
    @ViewBuilder
    private func makeContent() -> some View {
        VStack(spacing: 0) {
            if expandDirection == .down {
                content()
                Handle()
            } else {
                Handle()
                content()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: (expandDirection == .up) ? .top : .bottom)
        .background(.ultraThickMaterial)
        .roundedBorder(.secondary, width: 0.1, cornerRadius: 10)
        .shadow(color: .black.opacity(0.35), radius: 10.0)
        .animation(dragState.isDragging ? nil : .customSpring, value: heightFactor)
    }
    
    private func makeGesture(for frame: CGRect) -> some Gesture {
        DragGesture()
            .updating($dragState) { drag, state, transaction in
                state = .dragging(translation: drag.translation)
            }
            .onEnded { drag in
                onDragEnded(drag: drag, frame: frame)
            }
    }
    
    private func onDragEnded(drag: DragGesture.Value, frame: CGRect) {
                
        // the prededicted drag y end location as a percent of the frame
        let percentY = (drag.predictedEndLocation.y / frame.height)
        
        if percentY <= 0.33 {
            heightFactor = 0.1
        } else if percentY > 0.33 && percentY <= 0.66 {
            heightFactor = 0.5
        } else {
            heightFactor = 1.0
        }
    }
}

// MARK: -

/// A pill shaped handle view
///
fileprivate struct Handle: View { // TODO: Change the cursor type to arrow
    
    private let thickness: CGFloat = 5.0
    
    private let width: CGFloat = 40
    
    var body: some View {
        RoundedRectangle(cornerRadius: thickness / 2.0)
            .frame(width: width, height: thickness)
            .foregroundColor(.secondary)
            .padding(5)
    }
}
