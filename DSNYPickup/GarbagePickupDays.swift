//
//  ContentView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/4/21.
//

import SwiftUI
import Collections

struct GarbagePickupDays: View {    
    @State var textString = ""
    let columns = Array(repeating: GridItem(.flexible()), count: 6)
    let testArray: [String] = ["Thursday", "Tuesday", "Friday"]
    @State var days: OrderedDictionary = ["Monday": false, "Tuesday" : false, "Wednesday" : false, "Thursday": false, "Friday": false, "Saturday": false]
    
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
                
                // Garbage
                GridRow {
                    ForEach(days.values, id: \.self) { day in
                        if day == true {
                            ColorSquare(color: .pink)
                        } else {
                            Text("")
                        }
                    }
                }
                
                // Large Items
                GridRow {
                    ForEach(0..<1) { _ in
                        
                        ColorSquare(color: .yellow)
                    }
                }
                
                // Recycling
                GridRow {
                    ForEach(0..<5) { _ in
                        
                        ColorSquare(color: .mint)
                    }
                }
                
                // Composting
                GridRow {
                    ForEach(0..<4) { _ in
                        
                        ColorSquare(color: .indigo)
                    }
                }
            }
            
            Spacer()
            
        }.onAppear {
                for pick in testArray {
                    for day in days.keys.sorted() {
                    if pick == day {
                        days[day] = true
                    } 
                }
            }
            let _ = print(days)
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

enum EnumDays: Int, CustomStringConvertible
{
    var description: String {
        switch self {
        case .MONDAY:
            return "Monday"
        case .TUESDAY:
            return "Tuesday"
        case .WEDNESDAY:
            return "Wednesday"
        case .THURSDAY:
            return "Thursday"
        case .FRIDAY:
            return "Friday"
        case .SATURDAY:
            return "Saturday"
        case .SUNDAY:
            return "Sunday"
        }
    }
    case MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY
}
