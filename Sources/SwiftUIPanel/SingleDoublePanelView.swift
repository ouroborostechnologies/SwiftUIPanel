//
//  PanelView.swift
//  Cartographer
//
//  Created by Connor Yass on 12/11/22.
//

import SwiftUI

/// A container view consisting of left and right sidebar panels that are displayed 1 at a time at the bottom of the screen.
/// An optional middle view can be provided to display on top of the two
///
struct SingleDoublePanelView<LeftPanelContent: View, RightPanelContent: View, MiddleContent: View>: View {
        
    /// Set to nil if neither panel should be shown
    @Binding var visiblePanel: PanelSide?
    
    // MARK: Left
    
    @ViewBuilder var leftPanelContent: () -> LeftPanelContent
    
    @GestureState private var leftDragState = DragState.inactive
    
    @State var leftPanelHeight: CGFloat = 0.5
    
    // MARK: Middle
    
    @ViewBuilder var middleContent: () -> MiddleContent
    
    // MARK: Right
    
    @ViewBuilder var rightPanelContent: () -> RightPanelContent
    
    @GestureState private var rightDragState = DragState.inactive
    
    @State var rightPanelHeight: CGFloat = 0.5
    
    // MARK: -
    
    public init(visiblePanel: Binding<PanelSide?>,
                leftPanelContent: @escaping () -> LeftPanelContent,
                leftPanelHeight: CGFloat = 0.5,
                middleContent: @escaping () -> MiddleContent,
                rightPanelContent: @escaping () -> RightPanelContent,
                rightPanelHeight: CGFloat = 0.5)
    {
        self._visiblePanel = visiblePanel
        self.leftPanelContent = leftPanelContent
        self.leftPanelHeight = leftPanelHeight
        self.middleContent = middleContent
        self.rightPanelContent = rightPanelContent
        self.rightPanelHeight = rightPanelHeight
    }
    
    // MARK: -
    
    var body: some View {
        VStack(spacing: 0) {
            
            middleContent()
            
            if let visiblePanel {
                Group {
                    switch visiblePanel {
                    case .left:
                        Panel(heightFactor: $leftPanelHeight, expandDirection: .up, content: leftPanelContent)
                            .transition(.move(edge: (visiblePanel == .left) ? .leading : .trailing))
                    case .right:
                        Panel(heightFactor: $rightPanelHeight, expandDirection: .up, content: rightPanelContent)
                            .transition(.move(edge: (visiblePanel == .right) ? .trailing : .leading))
                    }
                }
                .padding(Constants.padding)
            }
        }
    }

}

// MARK: -

struct PanelView_Previews: PreviewProvider {
        
    static var previews: some View {
        Group {
            DoublePanelView(showLeftPanel: .constant(true),
                            leftPanelContent: leftPanelContent,
                            middleContent: middleContent,
                            showRightPanel: .constant(true),
                            rightPanelContent: rightPanelContent)
            
            SingleDoublePanelView(visiblePanel: .constant(.right),
                                  leftPanelContent: leftPanelContent,
                                  middleContent: middleContent,
                                  rightPanelContent: rightPanelContent)
        }
        .background(Gradient(colors: [.pink, .orange]))
        .previewInterfaceOrientation(.landscapeLeft)
    }
    
    @ViewBuilder
    private static func leftPanelContent() -> some View {
        List {
            Text("left content")
        }
    }
    
    @ViewBuilder
    private static func rightPanelContent() -> some View {
        List {
            Text("right content")
        }
    }
    
    @ViewBuilder
    private static func middleContent() -> some View {
        Text("middle content")
    }
}

