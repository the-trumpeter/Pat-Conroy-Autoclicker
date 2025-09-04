//
//  ContentView.swift
//  menuBarAppTemplate
//
//  Created by Gill Palmer on 29/8/2025.
//

import SwiftUI
import Carbon

struct ContentView: View {
    
    @Binding var clickInterval: Double
    @Binding var useMinutes: Bool
    
    @State var recordingKeystroke = false
    @Binding var hotkey: HotKey?
    
    @Binding var interactionType: Interaction
    @EnvironmentObject var Clicking: ClickingClass

    @Binding var clickLocation: CGPoint?

	@Binding var repeatType: RepeatType
	@Binding var repeatTimes: Int

    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        
        VStack {
            
            //MARK: Interval
            HStack {
                Label("Click Interval: ", systemImage: "timer")
                    .frame(width: 105.0, alignment: .leading)
                Spacer()
                TextField(useMinutes ? "mins" : "secs", value: $clickInterval, format: .number)
                    .frame(minWidth: 40)
            }.disabled(Clicking.clicking)
            
            //MARK: Hotkey
            HStack(spacing: 3) {
                Label("Hotkey: ", systemImage: "command")
                    .frame(minWidth: 70, alignment: .leading)
                Spacer(minLength: 1)
                
                Button { hotkey = nil } label: {//CLEAR
                    Image(systemName: "trash")
                }.buttonStyle(.borderless)
                .accessibilityLabel("Clear hotkey")
                .disabled(hotkey==nil)
                
                Button {//RECORD
                    recordingKeystroke.toggle()
                } label: {
                    Text(hotkey?.description ?? "Record")
                        .foregroundStyle(recordingKeystroke ? .blue : .primary)
                }
                .onChange(of: interactionType) { oldValue, newValue in
                    if newValue == .spacebar { hotkey=nil }
                }
            }.disabled(
				interactionType != Interaction.leftMouseButton || Clicking.clicking)
			.padding(.bottom, 5)

            
            //MARK: Trigger
            if Clicking.clicking {
                Button {
                    loop.shared.stop()
                    print("stopped")
                } label: {
                    Text("Clicking...")
                        .frame(maxWidth: .infinity, minHeight: 25)
                }.buttonStyle(.borderedProminent)
                
            } else {
                Button {
                    loop.shared.start(
                        interactionType,
                        interval: clickInterval,
                        minutes: useMinutes,
                        mouseLocation: clickLocation,
						repeatType: repeatType,
						repeatTimes: repeatTimes
                    )
                    print("started")
                } label: {
                    Text("Not Clicking")
                        .frame(maxWidth: .infinity, minHeight: 25)
                }
            }
            
            //MARK: Advanced
            Menu("Advanced", systemImage: "gear") {
                
                Picker("Interaction", systemImage: "cable.connector.horizontal", selection: $interactionType) {
                    Text("Left click").tag(Interaction.leftMouseButton)
                    Text("Spacebar").tag(Interaction.spacebar)
                }.disabled(Clicking.clicking)
                Toggle("Count in minutes", isOn: $useMinutes).disabled(Clicking.clicking)

                Divider()
                Button("More...", systemImage: "gear") {
                    openWindow(id: "settings")
					NSApp.activate(ignoringOtherApps: true)
                }
				
            }
            
            //MARK: Quit
            Button { NSApplication.shared.terminate(self) } label: {
                Text("Quit v1.1").frame(maxWidth: .infinity)
            }.buttonStyle(.borderless)
            
        }.frame(width: 160, height: 141)
        .background(KeyCaptureView(recording: $recordingKeystroke, hotKey: $hotkey, onHotKey: {
                if recordingKeystroke { return }
				print("Hotkey pressed")
                if !Clicking.clicking {
                    loop.shared.start(
                        interactionType,
                        interval: clickInterval,
                        minutes: useMinutes,
                        mouseLocation: clickLocation,
						repeatType: repeatType,
						repeatTimes: repeatTimes
                    )
                } else {
                    loop.shared.stop()
                }
            }))
    }
}

#Preview {
    @Previewable @State var clicking = false
    @Previewable @State var activeView = 1
    @Previewable @State var clickLocation: CGPoint? = nil
    @Previewable @State var interactionType: Interaction = .leftMouseButton
    @Previewable @State var clickInterval = 1.0
    @Previewable @State var useMinutes = false
    @Previewable @State var hotkey: HotKey? = nil
	@Previewable @State var rType = RepeatType.untilStopped
	@Previewable @State var rTimes = 10

    ContentView(
        clickInterval: $clickInterval,
        useMinutes: $useMinutes,
        hotkey: $hotkey,
        interactionType: $interactionType,
        clickLocation: $clickLocation,
		repeatType: $rType,
		repeatTimes: $rTimes
	).environmentObject(ClickingClass.shared)//dunno if this works, guess I'll find out
	.padding()
}
