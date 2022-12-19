//
//  SwiftUIView.swift
//  
//
//  Created by Connor Yass on 12/19/22.
//

import SwiftUI

/// A container view consisting of a left and right sidebar panels. An optional middle view can be provided to display in between the two
///
public struct DoublePanelView<LeftPanelContent: View, RightPanelContent: View, MiddleContent: View>: View {
    
    // MARK: Left
    
    @Binding var showLeftPanel: Bool
    
    var leftPanelConfig: PanelConfig = .init()
    
    @ViewBuilder var leftPanelContent: () -> LeftPanelContent
        
    @State var leftPanelHeight: CGFloat = 0.5
    
    // MARK: Middle
    
    @ViewBuilder var middleContent: () -> MiddleContent
    
    // MARK: Right
    
    @Binding var showRightPanel: Bool
    
    var rightPanelConfig: PanelConfig = .init()
    
    @ViewBuilder var rightPanelContent: () -> RightPanelContent
        
    @State var rightPanelHeight: CGFloat = 0.5
    
    // MARK: -
    
    public init(showLeftPanel: Binding<Bool>,
                leftPanelConfig: PanelConfig = .init(),
                leftPanelContent: @escaping () -> LeftPanelContent,
                leftPanelHeight: CGFloat = 0.5,
                middleContent: @escaping () -> MiddleContent,
                showRightPanel: Binding<Bool>,
                rightPanelConfig: PanelConfig = .init(),
                rightPanelContent: @escaping () -> RightPanelContent,
                rightPanelHeight: CGFloat = 0.5)
    {
        self._showLeftPanel = showLeftPanel
        self.leftPanelConfig = leftPanelConfig
        self.leftPanelContent = leftPanelContent
        self.leftPanelHeight = leftPanelHeight
        self.middleContent = middleContent
        self._showRightPanel = showRightPanel
        self.rightPanelConfig = rightPanelConfig
        self.rightPanelContent = rightPanelContent
        self.rightPanelHeight = rightPanelHeight
    }
    
    // MARK: -
    
    var body: some View {
        HStack(spacing: 0) {
            if showLeftPanel {
                Panel(heightFactor: $leftPanelHeight, expandDirection: .down, content: leftPanelContent)
                    .frame(minWidth: leftPanelConfig.minWidth, idealWidth: leftPanelConfig.idealWidth, maxWidth: leftPanelConfig.maxWidth)
                    .transition(.move(edge: showLeftPanel ? .leading : .trailing))
                    .padding(Constants.padding)
            }
            
            Spacer()
            
            middleContent()
                .padding(.vertical, Constants.padding)
            
            Spacer()
            
            if showRightPanel {
                Panel(heightFactor: $rightPanelHeight, expandDirection: .down, content: rightPanelContent)
                    .frame(minWidth: rightPanelConfig.minWidth, idealWidth: rightPanelConfig.idealWidth, maxWidth: rightPanelConfig.maxWidth)
                    .transition(.move(edge: showRightPanel ? .trailing : .leading))
                    .padding(Constants.padding)
            }
        }
    }
}
