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
    
    func start(_ interaction: Interaction, interval invl: TimeInterval, minutes: Bool, mouseLocation: CGPoint?) {
        stop() // cancel any existing timer
        let calculatedInterval = if minutes { invl*60 } else { invl }
        
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: calculatedInterval)
        timer?.setEventHandler { [weak self] in
            self?.performAction(interaction, mouseLocation: mouseLocation)
        }
        timer?.resume()
        
        print("Loop started with interval \(invl)s")
    }
    
    func stop() {
        timer?.cancel()
        timer = nil
        print("Loop stopped")
    }
    
    
    private func performAction(_ interaction: Interaction, mouseLocation: CGPoint?) {//MARK: PERFORM
        switch interaction {
        case .leftMouseButton:
            let mousePoint = mouseLocation ?? Interact.shared.currentMouseLocationForCGEvent()
            Interact.shared.simulateMouseClick(at: mousePoint)
        case .spacebar:
            Interact.shared.pressSpacebar()
        }
    }
}


@main
struct PatConroyAutoclicker: App {
    
    @State var clicking = false
    @State var activeView = 1
    @State var clickLocation: CGPoint? = nil
    @State var interactionType: Interaction = .leftMouseButton
    @State var clickInterval = 1.0
    @State var useMinutes = false
    @State var hotkey: HotKey? = nil
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        MenuBarExtra {
            ZStack {
                switch activeView {
                case 2:
                    mousePositionSheetView(clickLocation: $clickLocation, activeView: $activeView)
                        .onChange(of: scenePhase) { _, newPhase in
                            if newPhase == .background {
                                activeView=1
                            }
                        }
                default: ContentView(
                    clickInterval: $clickInterval,
                    useMinutes: $useMinutes,
                    hotkey: $hotkey,
                    interactionType: $interactionType,
                    clickLocation: $clickLocation,
                    clicking: $clicking,
                    activeView: $activeView
                )
                }
            }
            .padding()
        } label: {
            Image(systemName: clicking ? "computermouse.fill" : "computermouse")
        }
        .menuBarExtraStyle(.window)
    }
}
