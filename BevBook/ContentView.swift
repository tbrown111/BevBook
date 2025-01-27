//
//  ContentView.swift
//  BevBook
//
//  Created by Tyson Brown on 1/26/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Drink {
    let name: String
    let type: String
    let amount: Double
    let timestamp: Date
    var timeOfDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: timestamp)
    }
    var dayMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy" // Format: Day of the week, Month Day, Year
        return formatter.string(from: timestamp)
    }
}

struct ContentView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = true // Shared state for login status
    @State private var drinks: [Drink] = [] // List of drinks
    @State private var loadMoreDrinksEnabled = true // Whether to allow loading more drinks
    
    var body: some View {
        TabView {
            // Home Tab
            HomeView(drinks: $drinks, loadMoreDrinksEnabled: $loadMoreDrinksEnabled)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            // Stats Tab
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
            
            // Logout Tab
            Button(action: {
                logoutUser() // Log the user out
            }) {
                Text("Logout")
                    .foregroundColor(.red)
                    .fontWeight(.bold)
            }
            .tabItem {
                Label("Logout", systemImage: "rectangle.portrait.and.arrow.forward")
            }
        }
        .background(Color.white) // Background color behind TabView
        .onAppear {
            loadPastDrinks() // Load past drinks when the view appears
        }
    }
    
    private func logoutUser() {
        // Log the user out using Firebase
        do {
            try Auth.auth().signOut() // Log out the user
            isLoggedIn = false // Set isLoggedIn to false, navigating back to LoginView
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    private func loadPastDrinks() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("drinks")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 10) // Limit to the latest 10 drinks
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching drinks: \(error.localizedDescription)")
                    return
                }

                // Map Firestore documents to the Drink struct
                drinks = snapshot?.documents.compactMap { doc -> Drink? in
                    let data = doc.data()
                    
                    // Extract the fields and create a Drink object
                    guard let name = data["name"] as? String,
                          let type = data["type"] as? String,
                          let amount = data["amount"] as? Double,
                          let timestamp = data["timestamp"] as? Timestamp else {
                        return nil
                    }
                    
                    // Create and return a Drink object
                    return Drink(
                        name: name,
                        type: type,
                        amount: amount,
                        timestamp: timestamp.dateValue() // Convert the timestamp to a Date
                    )
            } ?? []
                print("Fetched drinks: \(drinks)") // Debug log
        }
    }
}

// MARK: - HomeView
struct HomeView: View {
    @Binding var drinks: [Drink]
    @Binding var loadMoreDrinksEnabled: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                // Title
                Text("BevBook 🍺🎉")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .padding(.top, 50)
                
                // Add Drink Button
                NavigationLink(destination: AddDrinkView(onAddDrink: { newDrink in
                    drinks.insert(newDrink, at: 0)})) {
                    Text("Add Drink")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding([.leading, .trailing], 20)
                }
                
                // Scrollable drinks list with swipe-to-delete functionality
                List {
                    ForEach(drinks, id: \.name) { drink in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(drink.name)
                                .font(.headline)
                            Text("""
                                \(drink.type)
                                \(drink.amount, specifier: "%.1f") oz
                                \(drink.timeOfDay) on \(drink.dayMonthYear)
                                """)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }
                    .onDelete(perform: deleteDrink) // Swipe-to-delete action
                }
                .padding(.top, 20)
                
                Spacer() // Push content up
            }
            .padding()
        }
    }
    
    private func deleteDrink(at offsets: IndexSet) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        // Loop through the deleted drink(s) and remove them from Firestore
        for index in offsets {
            let drink = drinks[index]
            
            // Find and delete the document from Firestore by drink name or another unique identifier
            db.collection("drinks")
                .whereField("name", isEqualTo: drink.name) // Example: query by drink name (make sure it's unique)
                .whereField("userId", isEqualTo: userId) // Make sure the drink belongs to the current user
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error deleting drink: \(error.localizedDescription)")
                        return
                    }
                    
                    // Assuming only one document per drink, delete the first match
                    if let document = snapshot?.documents.first {
                        document.reference.delete() { error in
                            if let error = error {
                                print("Error deleting document: \(error.localizedDescription)")
                            } else {
                                print("Document successfully deleted!")
                            }
                        }
                    }
                }
        }

        // Update the local drinks array after deletion
        drinks.remove(atOffsets: offsets)
    }
}

// MARK: - StatsView
struct StatsView: View {
    @State private var totalAmount: Double = 0.0 // To store total liquid consumed
    @State private var isLoading: Bool = true // To show loading indicator while fetching data

    var body: some View {
        VStack {
            Text("Stats")
                .font(.system(size: 32, weight: .bold, design: .default))
                .padding(.top, 50)

            // Display total amount or a loading message
            if isLoading {
                Text("Loading stats...")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                Text("Total Ounces of Alcohol Consumed: \(totalAmount, specifier: "%.1f") oz")
                    .font(.title)
                    .padding()
            }

            Spacer()
        }
        .onAppear {
            fetchStats()
        }
    }
    
    private func fetchStats() {
        // Check if the user is logged in
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }
        
        let db = Firestore.firestore()

        // Fetch drinks for the logged-in user from Firestore
        db.collection("drinks")
            .whereField("userId", isEqualTo: userId) // Filter by the current user's ID
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting documents: \(error.localizedDescription)")
                    isLoading = false
                    return
                }
                
                // Calculate the total amount of liquid consumed
                totalAmount = snapshot?.documents.reduce(0.0) { (result, document) -> Double in
                    // Assuming the 'amount' field is stored as a number (Double) in Firestore
                    let amount = document["amount"] as? Double ?? 0.0
                    return result + amount
                } ?? 0.0
                
                isLoading = false
            }
    }
}

struct AddDrinkView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var drinkName: String = ""
    @State private var drinkType: String = "Beer"
    @State private var drinkAmount: String = ""
    let drinkTypes = ["Beer", "Wine", "Whiskey", "Vodka", "Rum", "Tequila", "Gin", "Scotch", "Brandy", "Cognac", "Non-Alc"]
    let onAddDrink: (Drink) -> Void

    var body: some View {
        VStack {
            Text("Add a New Drink")
                .font(.title)
                .padding()

            // Drink Name Field
            TextField("Drink Name", text: $drinkName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Drink Type Picker
            Picker("Drink Type", selection: $drinkType) {
                ForEach(drinkTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()

            // Drink Amount Field
            TextField("Amount (oz)", text: $drinkAmount)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Add Drink Button
            Button(action: {
                addDrinkToDatabase()
            }) {
                Text("Add Drink")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
                    .padding([.leading, .trailing], 20)
            }
            .disabled(drinkName.isEmpty || drinkAmount.isEmpty) // Disable if inputs are invalid

            Spacer()
        }
        .padding()
    }

    private func addDrinkToDatabase() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let newDrink = [
            "name": drinkName,
            "type": drinkType,
            "amount": Int(drinkAmount) ?? 0,
            "userId": userId,
            "timestamp": Timestamp()
        ] as [String : Any]

        db.collection("drinks").addDocument(data: newDrink) { error in
            if let error = error {
                print("Error adding drink: \(error.localizedDescription)")
                return
            }
            // Create the Drink object
            let drink = Drink(
                name: drinkName,
                type: drinkType,
                amount: Double(drinkAmount) ?? 0,
                timestamp: Timestamp().dateValue()
            )
            onAddDrink(drink) // Pass the drink name back to the parent view
            presentationMode.wrappedValue.dismiss() // Close the AddDrinkView
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
