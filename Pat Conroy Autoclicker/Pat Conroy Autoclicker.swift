//
//FIXME:  menuBarAppTemplateApp.swift
//  menuBarAppTemplate
//
//  Created by Gill Palmer on 29/8/2025.
//

import SwiftUI
import Carbon.HIToolbox

typealias Colour = Color

class ClickingClass: ObservableObject {
	static let shared = ClickingClass()
	@Published var clicking: Bool = false
}

enum Interaction {
    case leftMouseButton
    case spacebar
}
enum RepeatType: Equatable, Hashable {
    case untilStopped
    case xTimes
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
	private var timesClicked: Int? = nil

    func start(
        _ interaction: Interaction,
        interval invl: TimeInterval,
        minutes: Bool,
        mouseLocation mLoc: CGPoint?,
        repeatType: RepeatType,
        repeatTimes: Int
    ) async {
        await stop() // cancel any existing timer
        let calculatedInterval = if minutes { invl*60 } else { invl }
		timesClicked = if repeatType == RepeatType.xTimes { 0 } else { nil }
		/*
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: calculatedInterval)
        timer?.setEventHandler { [weak self] in
            self?.performAction(interaction, mouseLocation: mLoc, repeatType: repeatType, repeatTimes: repeatTimes)
        }
        timer?.resume()
		 */
		await MainActor.run {
			ClickingClass.shared.clicking = true
		}
		/*
		 print("""
			STARTING:
				interc: \(interaction)
				invl: \(invl)
				mins?: \(minutes)
				mLoc: \(String(describing: mLoc))
				rType: \(repeatType)
				rTimes: \(repeatTimes)
			""")
		 */
        print("Loop started with interval \(invl)s")
    }
    
    func stop() async {
        print("Stopping...")
        if timer != nil { timer!.cancel(); print("cancelled timer") }
        timer = nil
        timesClicked = nil
        await MainActor.run { // Ensure logic values are in sync
            ClickingClass.shared.clicking = false
        }
        print("Loop stopped")
    }
    
    
	private func performAction(_ interaction: Interaction, mouseLocation: CGPoint?, repeatType: RepeatType, repeatTimes: Int) {//MARK: PERFORM

		//check
		if repeatType == RepeatType.xTimes {
			if timesClicked == nil {
				Task { await self.stop() }
				NSLog("TimesClicked was nil when it shouldn't've been!\ntimesClicked: \(String(describing: timesClicked))\nrepeatType: \(repeatType)\nrepeatTimes: \(repeatTimes)")
				return
			} else {
				if timesClicked! >= repeatTimes {
					print("Stopping clicking, after \(String(describing: timesClicked)) of \(repeatTimes) clicks.")
					Task { await self.stop() }
					return
				}
			}
		}

		//perform
		switch interaction {
		case .leftMouseButton:
			let mousePoint = mouseLocation ?? Interact.shared.currentMouseLocationForCGEvent()
			Interact.shared.simulateMouseClick(at: mousePoint)
		case .spacebar:
			Interact.shared.pressSpacebar()
		}

		//log & re-check
		if repeatType == .xTimes {
			if timesClicked == nil {
				Task { await self.stop() }
				NSLog("TimesClicked was nil when it shouldn't've been!\ntimesClicked: \(String(describing: timesClicked))\nrepeatType: \(repeatType)\nrepeatTimes: \(repeatTimes)")
			} else {

				//log
				timesClicked! += 1
				print(String(describing: timesClicked))
				//re-check
				if timesClicked! >= repeatTimes {
					print("Stopping clicking, after \(String(describing: timesClicked)) of \(repeatTimes) clicks.")
					Task { await self.stop() }
					return
				}

			}
		}

    }
}

@main
struct PatConroyAutoclicker: App {

	@StateObject var clickClass = ClickingClass.shared

	@State var clickLocation: CGPoint? = nil

	@State var clickInterval = 1.0
	@State var useMinutes = false

	@State var repeatType: RepeatType = .untilStopped
	@State var repeatTimes = 10

    @State var interactionType: Interaction = .leftMouseButton

    @State var hotkey: HotKey? = nil
    
    var body: some Scene {
        MenuBarExtra {
            ZStack {
                ContentView(
                    clickInterval: $clickInterval,
                    useMinutes: $useMinutes,
                    hotkey: $hotkey,
                    interactionType: $interactionType,
                    clickLocation: $clickLocation,
					repeatType: $repeatType,
					repeatTimes: $repeatTimes
				).environmentObject(ClickingClass.shared)
			}.onAppear() { print("Appeared") }
            .padding()
        } label: {
			Image(systemName: clickClass.clicking ? "computermouse.fill" : "computermouse")
        }
        .menuBarExtraStyle(.window)
        
		Window("Settings", id: "settings") {
			FullscreenSettingsView(
				interactionType: $interactionType,
				clickLocation: $clickLocation,
				repeatType: $repeatType,
				repeatTimes: $repeatTimes
			).environmentObject(ClickingClass.shared)
			.frame(width: 251, height: 125).padding()
		}.windowResizability(.contentSize)
    }
}

