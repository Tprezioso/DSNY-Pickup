//
//  ContentView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/4/21.
//

import SwiftUI

struct GarbageCollectionView: View {    
    let columns = Array(repeating: GridItem(.flexible()), count: 6)
    @StateObject var viewModel = GarbageCollectionStateModel()
    
    var body: some View {
        VStack {
            HStack {
                TextField("Address", text: $viewModel.textString, prompt: Text("When is collecting at..."))
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.search)
                    .onSubmit {
                        Task { @MainActor in
                            viewModel.garbageData = try await NetworkManager.shared.getGarbageDetails(atAddress: viewModel.textString)
                            viewModel.sortData()
                        }
                    }
            }.padding()

            Grid {
                GridRow { CalendarHeaderView() }
                
                // Garbage
                GridRow {
                    ForEach(viewModel.garbage.values, id: \.self) { day in
                        if day == true {
                            Image(systemName: "trash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.pink)
//                            ColorSquare(color: .pink)
                        } else {
                            Text("")
                        }
                    }
                }
                
                // Large Items
                GridRow {
                    ForEach(viewModel.largeItems.values, id: \.self) { day in
                        if day == true {
                            ColorSquare(color: .yellow)
                        } else {
                            Text("")
                        }
                    }
                }
                
                // Recycling
                GridRow {
                    ForEach(viewModel.recycling.values, id: \.self) { day in
                        if day == true {
                            ColorSquare(color: .mint)
                        } else {
                            Text("")
                        }
                    }
                }
                
                // Composting
                GridRow {
                    ForEach(viewModel.composting.values, id: \.self) { day in
                        if day == true {
                            ColorSquare(color: .indigo)
                        } else {
                            Text("")
                        }
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
        GarbageCollectionView()
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
