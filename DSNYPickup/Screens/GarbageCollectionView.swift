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
    init() {
        UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).adjustsFontSizeToFitWidth = true
    }
    
    var body: some View {
        
        ZStack {
                NavigationStack {
                    ScrollView {
                        VStack {
                            VStack(alignment: .leading) {
                                            HStack {
                                                Image(systemName: "magnifyingglass")
                                                    .foregroundColor(.secondary)
                                                TextField("Search...", text: $viewModel.textString, prompt: Text("When is collecting at..."))
                                            }
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .submitLabel(.search)
                                            .onSubmit {
                                                viewModel.getGarbageCollectionData()
                                            }
                                        }.padding()

                            GarbageCollectionGridView(
                                    garbage: viewModel.garbage,
                                    largeItems: viewModel.largeItems,
                                    recycling: viewModel.recycling,
                                    composting: viewModel.composting
                                )
                            Spacer()
                        }.onAppear {
                            viewModel.getGarbageCollectionData()
                        }
                    }.navigationTitle("DSNY Garbage Collection")
                }
            if viewModel.isLoading {
                ProgressView()
            }
        } .alert(item: $viewModel.alertItem) { alertItem in
            Alert.init(title: alertItem.title, message: alertItem.message, dismissButton: alertItem.dismissButton)
        }
        .onTapGesture {
            dismissKeyboardOnTap()
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

extension View {
  func dismissKeyboardOnTap() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil)
  }
}
