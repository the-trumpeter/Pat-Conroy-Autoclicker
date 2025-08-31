//
//  menuBarAppTemplateApp.swift
//  menuBarAppTemplate
//
//  Created by Gill Palmer on 29/8/2025.
//

import SwiftUI
import Carbon.HIToolbox

typealias Colour = Color

enum Interaction {
    case leftMouseButton
    case spacebar
}
class Interact {
    static let shared = Interact()
    
    func currentMouseLocationForCGEvent() -> CGPoint {
        var loc = NSEvent.mouseLocation
        if let screenHeight = NSScreen.main?.frame.height {
            // Flip the Y coordinate
            loc.y = screenHeight - loc.y
        }
        return loc
    }
    
    func simulateMouseClick(at point: CGPoint) {
        // Create a mouse down event
        let mouseDownEvent = CGEvent(
            mouseEventSource: nil, // Source (nil for default)
            mouseType: .leftMouseDown, // Event type
            mouseCursorPosition: point, // Location of the event
            mouseButton: .left // Mouse button
        )

        // Create a mouse up event
        let mouseUpEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: point,
            mouseButton: .left
        )

        // Post the events to the system
        if let mouseDownEvent = mouseDownEvent, let mouseUpEvent = mouseUpEvent {
            mouseDownEvent.post(tap: CGEventTapLocation.cghidEventTap)
            mouseUpEvent.post(tap: CGEventTapLocation.cghidEventTap)
        }
    }// simulateMouseClick(at: currentMouseLocationForCGEvent)
    
    func pressSpacebar() {
        let keyCode: CGKeyCode = CGKeyCode(kVK_Space)
        
        // Key down
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        // Key up
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
}

class loop {
    static let shared = loop()
    
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "autoclicker.timer")
    
    func start(_ interaction: Interaction, interval invl: TimeInterval, minutes: Bool) {
        stop() // cancel any existing timer
        let calculatedInterval = if minutes { invl*60 } else { invl }
        
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: calculatedInterval)
        timer?.setEventHandler { [weak self] in
            self?.performAction(interaction)
        }
        timer?.resume()
        
        print("Loop started with interval \(invl)s")
    }
    
    func stop() {
        timer?.cancel()
        timer = nil
        print("Loop stopped")
    }
    
    
    private func performAction(_ interaction: Interaction) {//MARK: PERFORM
        switch interaction {
        case .leftMouseButton:
            let mousePoint = Interact.shared.currentMouseLocationForCGEvent()
            Interact.shared.simulateMouseClick(at: mousePoint)
        case .spacebar:
            Interact.shared.pressSpacebar()
        }
    }
}


@main
struct PatConroyAutoclicker: App {
    @State var clicking = false
    @State private var pulse = false

    var body: some Scene {
        MenuBarExtra {
            ContentView(clicking: $clicking)
            .padding()
        } label: {
            Image(systemName: clicking ? "computermouse.fill" : "computermouse")
        }
        .menuBarExtraStyle(.window)
    }
}
