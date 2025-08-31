//
//  ContentView.swift
//  menuBarAppTemplate
//
//  Created by Gill Palmer on 29/8/2025.
//

import SwiftUI
import Carbon

struct mousePositionSheetView: View {
    @Binding var clickLocation: CGPoint?
    @Binding var activeView: Int
    @State private var mousePos: CGPoint = .zero
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Text("Position your mouse cursor").font(.headline)
            Text("\(Int(mousePos.x)), \(Int(mousePos.y))")
                .onReceive(timer) { _ in
                    let raw = NSEvent.mouseLocation
                    if let screenHeight = NSScreen.main?.frame.height {
                        mousePos = CGPoint(x: raw.x, y: screenHeight - raw.y)
                    } else {
                        mousePos = raw
                    }
                }
            HStack {
                Button("Cancel", systemImage: "escape") { activeView = 1 }.keyboardShortcut(.cancelAction)
                Button("Save", systemImage: "return") {
                    clickLocation = Interact.shared.currentMouseLocationForCGEvent()
                    activeView = 1
                }.keyboardShortcut(.defaultAction)
            }
        }.frame(width: 160, height: 141)
    }
}

struct ContentView: View {
    
    @Binding var clickInterval: Double
    @Binding var useMinutes: Bool
    
    @State var recordingKeystroke = false
    @Binding var hotkey: HotKey?
    
    @Binding var interactionType: Interaction
    @Binding var clickLocation: CGPoint?
    @Binding var clicking: Bool
    
    @Binding var activeView: Int
    
    
    var body: some View {
        
        VStack {
            
            //MARK: Interval
            HStack {
                Label("Click Interval: ", systemImage: "timer")
                    .frame(width: 105.0, alignment: .leading)
                Spacer()
                TextField(useMinutes ? "mins" : "secs", value: $clickInterval, format: .number)
                    .frame(minWidth: 40)
                    .disabled(clicking)
            }
            
            //MARK: Hotkey
            HStack(spacing: 3) {
                Label("Hotkey: ", systemImage: "command")
                    .frame(minWidth: 70, alignment: .leading)
                Spacer(minLength: 1)
                
                Button { hotkey = nil } label: {//CLEAR
                    Image(systemName: "trash")
                }.buttonStyle(.borderless)
                .accessibilityLabel("Clear hotkey")
                .disabled(
                    hotkey==nil || interactionType != Interaction.leftMouseButton || clicking
                )
                
                Button {//RECORD
                    loop.shared.stop()
                    clicking=false
                    recordingKeystroke.toggle()
                } label: {
                    Text(hotkey?.description ?? "Record")
                        .foregroundStyle(recordingKeystroke ? .blue : .primary)
                }.disabled(
                    interactionType != Interaction.leftMouseButton || clicking
                )
                .onChange(of: interactionType) { oldValue, newValue in
                    if newValue == .spacebar { hotkey=nil }
                }
            }.padding(.bottom, 5)
            
            
            //MARK: Trigger
            if clicking {
                Button {
                    loop.shared.stop()
                    clicking=false
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
                        mouseLocation: clickLocation
                    )
                    clicking=true
                    print("started")
                } label: {
                    Text("Not Clicking")
                        .frame(maxWidth: .infinity, minHeight: 25)
                }
            }
            
            //MARK: Advanced
            Menu {
                
                Picker(selection: $interactionType) {
                    Text("Left click").tag(Interaction.leftMouseButton)
                    Text("Spacebar").tag(Interaction.spacebar)
                } label: {
                    Label("Interaction", systemImage: "cable.connector")
                }
                
                Toggle("Count in minutes", isOn: $useMinutes).disabled(clicking)
                
                Menu {
                    Text(clickLocation==nil ? "Auto" : "\(Int(clickLocation!.x)), \(Int(clickLocation!.y))")
                    Divider()
                    Button("Clear", systemImage: "trash") { clickLocation=nil }.disabled(clickLocation==nil)
                    Button("Set click location...", systemImage: "mappin") { activeView=2 }
                } label: { Label("Click location", systemImage: "map") }.disabled(interactionType != .leftMouseButton)
                
            } label: {
                 Text("Advanced")
                 Image(systemName: "gear")
            }.disabled(clicking)
            
            //MARK: Quit
            Button { NSApplication.shared.terminate(self) } label: {
                Text("Quit v1.1").frame(maxWidth: .infinity)
            }.buttonStyle(.borderless)
            
            
        }.frame(width: 160, height: 141)
        .background(KeyCaptureView(recording: $recordingKeystroke, hotKey: $hotkey, onHotKey: {
                if recordingKeystroke { return }
                clicking.toggle()
                if clicking {
                    loop.shared.start(
                        interactionType,
                        interval: clickInterval,
                        minutes: useMinutes,
                        mouseLocation: clickLocation
                    )
                } else {
                    loop.shared.stop()
                }
            }))
    }
}
