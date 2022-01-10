import SwiftUI

extension View {
  func whenHovered(_ mouseIsInside: @escaping (Bool) -> Void) -> some View {
    modifier(MouseInsideModifier(mouseIsInside))
  }
  
  /// Applies the given transform if the given condition evaluates to `true`.
  /// - Parameters:
  ///   - condition: The condition to evaluate.
  ///   - transform: The transform to apply to the source `View`.
  /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
  @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}

// MARK: -modifiers
struct MouseInsideModifier: ViewModifier {
  let mouseIsInside: (Bool) -> Void
  
  init(_ mouseIsInside: @escaping (Bool) -> Void) {
    self.mouseIsInside = mouseIsInside
  }
  
  func body(content: Content) -> some View {
    content.background(
      GeometryReader { proxy in
        Representable(mouseIsInside: mouseIsInside,
                      frame: proxy.frame(in: .global))
      }
    )
  }
  
  private struct Representable: NSViewRepresentable {
    let mouseIsInside: (Bool) -> Void
    let frame: NSRect
    
    func makeCoordinator() -> Coordinator {
      let coordinator = Coordinator()
      coordinator.mouseIsInside = mouseIsInside
      return coordinator
    }
    
    class Coordinator: NSResponder {
      var mouseIsInside: ((Bool) -> Void)?
      
      override func mouseEntered(with event: NSEvent) {
        mouseIsInside?(true)
      }
      
      override func mouseExited(with event: NSEvent) {
        mouseIsInside?(false)
      }
    }
    
    func makeNSView(context: Context) -> NSView {
      let view = NSView(frame: frame)
      
      let options: NSTrackingArea.Options = [
        .mouseEnteredAndExited,
        .inVisibleRect,
        .activeInKeyWindow
      ]
      
      let trackingArea = NSTrackingArea(rect: frame,
                                        options: options,
                                        owner: context.coordinator,
                                        userInfo: nil)
      
      view.addTrackingArea(trackingArea)
      
      return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
      nsView.trackingAreas.forEach { nsView.removeTrackingArea($0) }
    }
  }
}
