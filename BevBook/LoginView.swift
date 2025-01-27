//
//  LoginView.swift
//  BevBook
//
//  Created by Tyson Brown on 1/26/25.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage = ""
    
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false  // Use @AppStorage to persist login status globally


    var body: some View {
        NavigationStack {
            VStack {
                // Title
                Text("BevBook 🍺🎉")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .padding(.top, 50)
                
                Spacer().frame(height: 40)
                
                // Username Field
                TextField("Username", text: $username)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)
                    .padding([.leading, .trailing], 20)
                
                Spacer().frame(height: 20)
                
                // Password Field
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)
                    .padding([.leading, .trailing], 20)
                
                Spacer().frame(height: 30)
                
                // Error message if login fails
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.bottom, 10)
                }
                
                // Login Button
                Button(action: {
                    loginUser() // Handle login action
                }) {
                    Text("Login")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding([.leading, .trailing], 20)
                }
                
                Spacer().frame(height: 20)
                
                // "Or" Button
                Text("OR")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                
                Spacer().frame(height: 20)
                
                // Sign Up Button
                NavigationLink(destination: CreateAccountView()) {
                    Text("Sign Up")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    func loginUser() {
        Auth.auth().signIn(withEmail: username, password: password) { result, error in
            if let error = error {
                // Handle login error
                errorMessage = error.localizedDescription
            } else {
                // Successfully logged in
                errorMessage = "already logged in"
                isLoggedIn = true // Trigger navigation or update UI
                
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

