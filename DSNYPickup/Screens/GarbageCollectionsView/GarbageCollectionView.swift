//
//  ContentView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/4/21.
//

import SwiftUI
import Lottie

struct GarbageCollectionView: View {
    @StateObject var viewModel = GarbageCollectionStateModel()
    @StateObject private var locationManager = LocationManager()
    @StateObject var notificationManager = NotificationManager()
    @Environment(\.managedObjectContext) var viewContext
    
    init() {
        UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).adjustsFontSizeToFitWidth = true
    }
    
    var body: some View {
        ZStack {
                VStack {
                    ScrollView {
                    VStack(alignment: .leading) {
                        Text("\(viewModel.stringViewString)")
                            .font(.title)
                            .padding(.top)
                            .padding(.horizontal)
                        
                        GarbageCollectionGridView(garbageData: viewModel.garbageData)
                        Spacer()
                    }.onAppear {
                        viewModel.getGarbageCollectionData()
                    }
                    .searchable(text: $viewModel.searchString, placement: .navigationBarDrawer(displayMode: .always), prompt: viewModel.searchString.isEmpty ? "When is Collection at..." : viewModel.searchString) {
                        ForEach(viewModel.places) { place in
                            SearchView(place: place.name, viewModel: viewModel)
                        }
                    }
                    .onSubmit(of: .search) {
                        viewModel.getGarbageCollectionData()
                    }
                    
                    
                }.navigationTitle("DSNY Garbage Collection")
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .toolbarBackground(Color.accentColor, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .onAppear {
                        viewModel.getGarbageCollectionData()
                    }
                    .searchable(text: $viewModel.searchString, placement: .navigationBarDrawer(displayMode: .always), prompt: viewModel.searchString.isEmpty ? "When is Collection at..." : viewModel.searchString) {
                        ForEach(viewModel.places) { place in
                            SearchView(place: place.name, viewModel: viewModel)
                        }
                    }
                    .onSubmit(of: .search) {
                        viewModel.getGarbageCollectionData()
                    }
                    .onChange (of: viewModel.searchString, perform: { searchText in
                        viewModel.search(text: searchText, region: locationManager.region)
                    })
                Button {
                    let newTask = GarbageCollection(context: viewContext)
                    newTask.id = UUID()
                    newTask.formattedAddress = viewModel.garbageData?.formattedAddress
                    newTask.bulkPickupCollectionSchedule = viewModel.garbageData?.bulkPickupCollectionSchedule
                    newTask.organicsCollectionSchedule = viewModel.garbageData?.organicsCollectionSchedule
                    newTask.regularCollectionSchedule = viewModel.garbageData?.regularCollectionSchedule
                    newTask.recyclingCollectionSchedule = viewModel.garbageData?.recyclingCollectionSchedule
                    newTask.commercialRoutingTime = viewModel.garbageData?.routingTime?.commercialRoutingTime
                    newTask.residentialRoutingTime = viewModel.garbageData?.routingTime?.residentialRoutingTime
                    newTask.mixedUseRoutingTime = viewModel.garbageData?.routingTime?.mixedUseRoutingTime
                    newTask.additionalLinks = viewModel.garbageData?.routingTime?.additionalLinks
//                    newTask.savedDate = 
                    try? viewContext.save()
                    viewModel.isAddFavoritesEnabled = true
                } label: {
                    Label("Add to Favorites", systemImage: "star")
                        .bold()
                }.disabled(viewModel.stringViewString.isEmpty)
                    .padding()
                    .buttonStyle(RoundedRectangleButtonStyle())
            }
            
            if viewModel.isLoading {
                ProgressView()
            }
            if viewModel.isAddFavoritesEnabled {
                LottieView(name: "Check", loopMode: .playOnce, isShowing: $viewModel.isAddFavoritesEnabled)
                    .frame(width: 250, height: 250)
                
            }
        }.alert(item: $viewModel.alertItem) { alertItem in
            Alert.init(title: alertItem.title, message: alertItem.message, dismissButton: alertItem.dismissButton)
        }
        .onTapGesture {
            dismissKeyboardOnTap()
        }
        .onAppear {
            notificationManager.reloadAuthorizationStatus()
        }
        .onDisappear {
            notificationManager.reloadLocalNotifications()
        }
        .onChange(of: notificationManager.authorizationStatus) { authorizationStatus in
            switch authorizationStatus {
            case .notDetermined:
                notificationManager.requestAuthorization()
            case .authorized:
                notificationManager.reloadLocalNotifications()
            default:
                break
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GarbageCollectionView()
    }
}

enum EnumDays: Int, CustomStringConvertible, CaseIterable {
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
    
    var number: Int {
        switch self {
        case .MONDAY:
            return 2
        case .TUESDAY:
            return 3
        case .WEDNESDAY:
            return 4
        case .THURSDAY:
            return 5
        case .FRIDAY:
            return 6
        case .SATURDAY:
            return 7
        case .SUNDAY:
            return 1
        }
    }
    
    static func dayToNumber(_ days: [String]) -> [EnumDays?] {
       return days.map { day in
           self.allCases.first {"\($0)" == day }
        }
    }
    
    static func dayBefore(_ days: [String]) -> [EnumDays?] {
        return days.map { day in
            self.allCases.first {"\($0.next())" == day }
         }
     }
    
    case MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY
}

struct RoundedRectangleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label.foregroundColor(.white)
            Spacer()
        }
        .padding()
        .background(Color.accentColor.cornerRadius(8))
        .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct AddressSearchView: View {
    @StateObject var viewModel: GarbageCollectionStateModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search...", text: $viewModel.searchString, prompt: Text("When is collecting at..."))
                Button {
                    print("Save")
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .foregroundColor(.accentColor)
                        .frame(width: 30, height: 30)
                }
                
            }
            .font(.title2)
            .textFieldStyle(.roundedBorder)
            .submitLabel(.search)
            .onSubmit {
                viewModel.getGarbageCollectionData()
            }
        }.padding()
    }
}

struct SearchView: View {
    var place: String
    @StateObject var viewModel: GarbageCollectionStateModel
    @Environment(\.dismissSearch) private var dismissSearch
    
    var body: some View {
        Text(place)
            .onTapGesture {
                Task { @MainActor in
                    viewModel.searchString = place
                    viewModel.getGarbageCollectionData()
                }
                dismissSearch()
            }
    }
}

extension CaseIterable where Self: Equatable, AllCases: BidirectionalCollection {
    func previous() -> Self {
        let all = Self.allCases
        let idx = all.firstIndex(of: self)!
        let previous = all.index(before: idx)
        return all[previous < all.startIndex ? all.index(before: all.endIndex) : previous]
    }

    func next() -> Self {
        let all = Self.allCases
        let idx = all.firstIndex(of: self)!
        let next = all.index(after: idx)
        return all[next == all.endIndex ? all.startIndex : next]
    }
}
