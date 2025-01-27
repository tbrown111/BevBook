//
//  BevBookApp.swift
//  BevBook
//
//  Created by Tyson Brown on 1/26/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct BevBookApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false  // Use @AppStorage for global state
    var body: some Scene {
        WindowGroup {
            // Conditionally show the LoginView or ContentView
            if isLoggedIn {
                ContentView() // Show ContentView if logged in
            } else {
                LoginView() // Show LoginView if not logged in
            }
        }
    }
}
