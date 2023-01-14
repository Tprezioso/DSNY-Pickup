//
//  ContentView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/4/21.
//

import SwiftUI

struct GarbagePickupDays: View {    
    @State var textString = ""
    let columns = Array(repeating: GridItem(.flexible()), count: 6)
    
    var body: some View {
        VStack {
            HStack {
                TextField("Address", text: $textString, prompt: Text("When is collecting at..."))
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.search)
                    .onSubmit {
                        Task { @MainActor in
                            try await NetworkManager.shared.getGarbageDetails(atAddress: textString)
                        }
                    }
            }.padding()

            Grid {
                GridRow { CalendarHeaderView() }
                GridRow {
                    ForEach(0..<6) { _ in
                        ColorSquare(color: .pink)
                    }
                }
                GridRow {
                    ForEach(0..<1) { _ in
                        
                        ColorSquare(color: .yellow)
                    }
                }
                GridRow {
                    ForEach(0..<5) { _ in
                        
                        ColorSquare(color: .mint)
                    }
                }
                GridRow {
                    ForEach(0..<4) { _ in
                        
                        ColorSquare(color: .indigo)
                    }
                }
            }
            
            Spacer()
            
        }.onAppear {
            
        }
    }
}

struct ColorSquare: View {
    let color: Color
    
    var body: some View {
        color
        .frame(width: 50, height: 50)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GarbagePickupDays()
    }
}
