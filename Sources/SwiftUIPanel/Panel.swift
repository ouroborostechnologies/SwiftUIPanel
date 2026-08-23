//
//  SwiftUIView.swift
//
//
//  Created by Connor Yass on 12/19/22.
//

import SwiftUI

public enum PanelDirection {
  case up
  case down
}

public enum _DragState {
  case dragging(startHeight: CGFloat)
}

@Observable
public class PanelViewModel {
  
  /// The direction in which the panel can be expanded
  public var direction: PanelDirection
  
  /// The state of the current drag operation
  public private(set) var dragState: _DragState? = nil
  
  /// The raw height of the entire panel (not just the contents)
  public private(set) var currentHeight: CGFloat = 100.0
  
  /// The height of the draggable handle region of the panel
  public var dragRegionHeight: CGFloat = 18.0
  
  /// The height of the panel's toolbar. This part is always visible
  public var toolbarHeight: CGFloat = 40.0
  
  /// The corner radius of the panel
  public var cornerRadius: CGFloat = 14
  
  /// The visual and clip shape of the panel computed based on the `cornerRadius` and <some other variable>
  public var shape: some Shape {
    RoundedRectangle(cornerRadius: cornerRadius)
  }
  
  public init(direction: PanelDirection) {
    self.direction = direction
  }
  
  private var directionalFactor: CGFloat {
    return (direction == .up) ? -1.0 : 1.0
  }
  
  public func onDragChange(_ value: DragGesture.Value, frame: CGRect) {
    let deltaY = value.translation.height * directionalFactor
    
    switch dragState {
    case .dragging(let startHeight):
      print("drag changed: \(deltaY)")
      setCurrentHeight(startHeight + deltaY, maxHeight: frame.height)
    case nil:
      print("drag start: \(deltaY)")
      let newDragState: _DragState = .dragging(startHeight: currentHeight)
      setCurrentHeight(currentHeight + deltaY, maxHeight: frame.height)
      dragState = newDragState
    }
  }
  
  public func onDragEnd(_ value: DragGesture.Value, frame: CGRect) {
    let deltaY = value.translation.height * directionalFactor
    print("drag ended: \(deltaY)")
    
    switch dragState {
    case .dragging(let startHeight):
      let endHeight = startHeight + deltaY
      processDragEnd(endHeight: endHeight, maxHeight: frame.height)
    case nil:
      break
    }
    
    dragState = nil
  }
  
  private func setCurrentHeight(_ newValue: CGFloat, maxHeight: CGFloat) {
    let minimumPanelHeight = dragRegionHeight + toolbarHeight
    currentHeight = min(max(minimumPanelHeight, newValue), maxHeight)
  }
  
  private func processDragEnd(endHeight: CGFloat, maxHeight: CGFloat) {
    let percent = endHeight / maxHeight
    print(percent)
    
    var resolvedPercent = 0.0
    
    if percent <= 0.4 {
      resolvedPercent = 0.0
    } else if percent > 0.4 && percent <= 0.7 {
      resolvedPercent = 0.5
    } else {
      resolvedPercent = 1.0
    }
    
    let newEndHeight = resolvedPercent * maxHeight
    setCurrentHeight(newEndHeight, maxHeight: maxHeight)
  }
}

/// A vertically resizable card with rounded corners
///
public struct Panel<Content: View, Toolbar: View>: View {
  
  @Binding public var model: PanelViewModel
  
  /// The main content that gets displayed inside the panel
  @ViewBuilder public var content: () -> Content
  
  /// Toolbar content is always visible even when the panel is closed
  @ViewBuilder public var toolbar: () -> Toolbar
  
  /// A debug tool that draws borders around the panel's main components
  public var showFrames: Bool = false
  
  private let coordinateSpace: CoordinateSpace = .global
  
  public init(model: Binding<PanelViewModel>,
              content: @escaping () -> Content,
              toolbar: @escaping () -> Toolbar,
              showFrames: Bool = false)
  {
    self._model = model
    self.content = content
    self.toolbar = toolbar
    self.showFrames = showFrames
  }
  
  public var body: some View {
    GeometryReader { geometry in
      directionalVStack(model.direction, spacing: 0) {
        content(frame: geometry.frame(in: coordinateSpace))
      } b: {
        Color.clear.allowsHitTesting(false)
      }
      .animation(model.dragState == nil ? .spring : nil, value: model.currentHeight)
    }
    .if(showFrames) {
      $0.border(.red)
    }
  }
  
  @ViewBuilder
  private func content(frame: CGRect) -> some View {
    model.shape
      .fill(.regularMaterial)
      .frame(height: model.currentHeight)
      .shadow(radius: 10.0)
      .overlay(alignment: .top) {
        directionalVStack(model.direction, spacing: 0) {
          toolbar()
            .frame(height: model.toolbarHeight)
        } b: {
          content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } c: {
          dragHandle
            .frame(height: model.dragRegionHeight)
            .gesture(makeGesture(frame: frame))
        }
        .clipShape(model.shape)
      }
  }
  
  private var dragHandle: some View {
    Color.primary.opacity(0.001)
      .overlay {
        Capsule()
          .frame(width: 40, height: 6)
          .foregroundColor(.secondary)
      }
      .if(showFrames) {
        $0.border(.orange)
      }
  }
  
  private func makeGesture(frame: CGRect) -> some Gesture {
    DragGesture(coordinateSpace: coordinateSpace)
      .onChanged { model.onDragChange($0, frame: frame) }
      .onEnded { model.onDragEnd($0, frame: frame) }
  }
}

// MARK: -

fileprivate struct PanelControls: View {
  
  @Binding var model: PanelViewModel
  
  private var directionBinding: Binding<Bool> {
    .init {
      return model.direction == .up
    } set: {
      model.direction = $0 ? .up : .down
    }
  }
  
  var body: some View {
    List {
      Section {
        Toggle("Reverse direction", isOn: directionBinding)
      }
      Slider(value: $model.cornerRadius, in: .init(uncheckedBounds: (0.0, 100.0))) {
        Text("Corner radius")
      }
      Slider(value: $model.dragRegionHeight, in: .init(uncheckedBounds: (0.0, 100.0))) {
        Text("Handle height")
      }
      Slider(value: $model.toolbarHeight, in: .init(uncheckedBounds: (0.0, 100.0))) {
        Text("Toolbar height")
      }
    }
  }
}

// MARK: -

struct PanelDemoView: View {
  
  private enum Tab {
    case controls
    case scrollView
    case text
    case empty
  }
  
  @State var model: PanelViewModel = .init(direction: .up)
  
  @State private var selectedTab: Tab = .controls
  
  var body: some View {
    Color.purple
      .overlay {
        Panel(model: $model) {
          content
        } toolbar: {
          toolbar
        }
        .padding()
      }
  }
  
  @ViewBuilder
  var content: some View {
    switch selectedTab {
    case .controls:
      PanelControls(model: $model)
    case .scrollView:
      List {
        ForEach(0..<50, id: \.self) {
          Text("\($0)")
        }
      }
    case .text:
      Text("Text")
    case .empty:
      EmptyView()
    }
  }
  
  var toolbar: some View {
    HStack {
      tabButton(systemImage: "slider.horizontal.3", tab: .controls)
        .help("Controls")
      tabButton(systemImage: "map", selectedSystemImage: "map.fill", tab: .scrollView)
        .help("Scroll View")
      tabButton(systemImage: "gearshape", selectedSystemImage: "gearshape.fill", tab: .text)
        .help("Text")
      tabButton(systemImage: "doc.text", selectedSystemImage: "doc.text.fill", tab: .empty)
        .help("Empty")
    }
    .font(.title3)
    .buttonStyle(.plain)
  }
  
  @ViewBuilder
  private func tabButton(systemImage: String, selectedSystemImage: String? = nil, tab: Tab) -> some View {
    Button {
      selectedTab = tab
    } label: {
      if selectedTab == tab {
        Image(systemName: selectedSystemImage ?? systemImage)
          .foregroundColor(.accentColor)
      } else {
        Image(systemName: systemImage)
          .foregroundColor(.secondary)
      }
    }
  }
}


// MARK: -

@ViewBuilder
fileprivate func directionalVStack<A: View, B: View, C: View>(_ direction: PanelDirection,
                                                              spacing: CGFloat = 0.0,
                                                              a: () -> A,
                                                              b: () -> B,
                                                              c: () -> C) -> some View
{
  switch direction {
  case .up:
    VStack(spacing: spacing) {
      c()
      b()
      a()
    }
  case .down:
    VStack(spacing: spacing) {
      a()
      b()
      c()
    }
  }
}

@ViewBuilder
fileprivate func directionalVStack<A: View, B: View>(_ direction: PanelDirection,
                                                     spacing: CGFloat = 0.0,
                                                     a: () -> A,
                                                     b: () -> B) -> some View
{
  switch direction {
  case .up:
    VStack(spacing: spacing) {
      b()
      a()
    }
  case .down:
    VStack(spacing: spacing) {
      a()
      b()
    }
  }
}
