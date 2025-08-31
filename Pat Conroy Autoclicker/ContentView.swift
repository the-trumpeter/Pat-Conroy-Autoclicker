//
//  ContentView.swift
//  menuBarAppTemplate
//
//  Created by Gill Palmer on 29/8/2025.
//

import SwiftUI
import Carbon

struct ContentView: View {
    @State var clickInterval = 1.0
    @State var useMinutes = false
    @State var recordingKeystroke: Bool = false
    @State var hotkey: HotKey? = nil
    @Binding var clicking: Bool
    @State var interactionType: Interaction = .leftMouseButton
    
    var body: some View {
        
        VStack {
            
            //MARK: Interval
            HStack {
                Label("Click Interval: ", systemImage: "computermouse.fill")
                    .frame(width: 102.0, alignment: .leading)
                Spacer()
                TextField(useMinutes ? "mins" : "secs", value: $clickInterval, format: .number)
                    .frame(minWidth: 40)
                    .disabled(clicking)
            }
            
            //MARK: Hotkey
            HStack(spacing: 3) {
                Label("Hotkey: ", systemImage: "command.square.fill")
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
                    loop.shared.start(interactionType, interval: clickInterval, minutes: useMinutes)
                    clicking=true
                    print("started")
                } label: {
                    Text("Not Clicking")
                        .frame(maxWidth: .infinity, minHeight: 25)
                }
            }
            
            //MARK: Dropdown tests
            Menu {
                
                Picker(selection: $interactionType) {
                    Text("Left click").tag(Interaction.leftMouseButton)
                    Text("Spacebar").tag(Interaction.spacebar)
                } label: {
                    Label("Interaction", systemImage: "cable.connector")
                }.disabled(clicking)
                Toggle("Use minutes", isOn: $useMinutes).disabled(clicking)
                
            } label: {
                 Text("Advanced")
                 Image(systemName: "gear")
            }
            
            //MARK: Quit
            Button { NSApplication.shared.terminate(self) } label: {
                Text("Quit v1.0").frame(maxWidth: .infinity)
            }.buttonStyle(.borderless)
            
            
        }.frame(width: 160
        )
        .background(KeyCaptureView(recording: $recordingKeystroke, hotKey: $hotkey, onHotKey: {
                if recordingKeystroke { return }
                clicking.toggle()
                if clicking {
                    loop.shared.start(interactionType, interval: clickInterval, minutes: useMinutes)
                } else {
                    loop.shared.stop()
                }
            }))
    }
}

#Preview {
    @Previewable @State var clicking = false
    ContentView(clicking: $clicking).padding()
}
