//
//  ContentView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/4/21.
//

import SwiftUI

struct GarbagePickupDays: View {    
    @State var textString = ""
    
    var body: some View {
        VStack {
            TextField("Address", text: $textString, prompt: Text("When is collecting at..."))
                .padding()
            Text("InfoView")
                .onTapGesture {
                    Task { @MainActor in
                        try await NetworkManager.shared.getGarbageDetails(atAddress: textString)
                    }
                }
        }.onAppear {
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GarbagePickupDays()
    }
}
