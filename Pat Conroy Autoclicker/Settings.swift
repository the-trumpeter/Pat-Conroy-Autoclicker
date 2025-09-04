//
//  Settings.swift
//  Pat Conroy Autoclicker
//
//  Created by Gill Palmer on 2/9/2025.
//

import SwiftUI



struct mousePositionSheetView: View {
    @Binding var cLoc: CGPoint?
    @Binding var sSh: Bool
    @State private var mPos: CGPoint = .zero
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Text("Position your mouse cursor").font(.headline)
            Text("\(Int(mPos.x)), \(Int(mPos.y))")
                .onReceive(timer) { _ in
                    let raw = NSEvent.mouseLocation
                    if let screenHeight = NSScreen.main?.frame.height {
                        mPos = CGPoint(x: raw.x, y: screenHeight - raw.y)
                    } else {
                        mPos = raw
                    }
                }
            HStack {
                Button("Cancel", systemImage: "escape") { sSh = false }.keyboardShortcut(.cancelAction)
                Button("Save", systemImage: "return") {
                    cLoc = Interact.shared.currentMouseLocationForCGEvent()
                    sSh = false
                }.keyboardShortcut(.defaultAction)
            }
        }
    }
}



struct FullscreenSettingsView: View {

	@Binding var interactionType: Interaction

    @Binding var clickLocation: CGPoint?

	@Binding var repeatType: RepeatType
    @Binding var repeatTimes: Int

    @State var showingSheet = false

	@EnvironmentObject var Clicking: ClickingClass

    var body: some View {
        HStack {
            
			VStack(alignment: .center) { //MARK: Click location
                
                Label("Click location", systemImage: "map").font(.headline)
                Spacer()
                Text(clickLocation==nil ?
                     "Automatic" :
                        "\(Int(clickLocation!.x)), \(Int(clickLocation!.y))")

				Button("Change", systemImage: "mappin") {
                    showingSheet = true
                }
                .buttonStyle(.borderedProminent)
                .sheet(isPresented: $showingSheet) {
                    mousePositionSheetView(
                        cLoc: $clickLocation, sSh: $showingSheet
                    ).padding()
                }
                Button("Clear", systemImage: "trash") { }
                Spacer()
                
			}.frame(width: 112.5)
			.padding(8)
			.background(.quinary)
			.clipShape(RoundedRectangle(cornerRadius: 5))
			.disabled(interactionType != .leftMouseButton)

			VStack(alignment: .center) { //MARK: Repeat

                Label("Repeat", systemImage: "repeat").font(.headline)
                Spacer()

                Picker("Repeat...", selection: $repeatType) {
                    
                    Text("until stopped").tag(RepeatType.untilStopped)
                    
                    HStack(spacing: 4) {
                        TextField("times",
                                  value: $repeatTimes, format: .number
                        ).frame(width: 40).labelsHidden()
                        Text("times")
                    }.tag(RepeatType.xTimes)
                    
                }.pickerStyle(.inline).labelsHidden()
                
                Spacer()
			}.frame(width: 112.5)
			.padding(8)
			.background(.quinary)
			.clipShape(RoundedRectangle(cornerRadius: 5))

		}.disabled(Clicking.clicking)

    }
}

#Preview {
    @Previewable @State var cPos: CGPoint? = nil
	@Previewable @State var iType = Interaction.leftMouseButton
	@Previewable @State var rType = RepeatType.untilStopped
	@Previewable @State var rTimes = 10

	FullscreenSettingsView(
		interactionType: $iType,
		clickLocation: $cPos,
		repeatType: $rType,
		repeatTimes: $rTimes
	).frame(width: 251, height: 125).padding()
}
