//
//  CreateAccountView.swift
//  BevBook
//
//  Created by Tyson Brown on 1/26/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CreateAccountView: View {
    @State private var name = ""
    @State private var email = ""
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
                
                // Name Field
                TextField("Name", text: $name)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)
                    .padding([.leading, .trailing], 20)
                
                Spacer().frame(height: 20)
                
                // Username Field
                TextField("Email", text: $email)
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
                
                // Create Account Button
                Button(action: {
                    // Ensure the fields are filled out
                    guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
                        print("Please fill in all fields")
                        errorMessage = "P"
                        return
                    }
                    
                    // Create user with Firebase Authentication
                    Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                        if let error = error {
                            // Handle errors (e.g., email already in use)
                            print("Error creating user: \(error.localizedDescription)")
                            errorMessage = error.localizedDescription
                        } else {
                            // Successfully created user, store additional data in Firestore
                            if let user = authResult?.user {
                                // Store the user's name and email in Firestore
                                let db = Firestore.firestore()
                                db.collection("users").document(user.uid).setData([
                                    "name": name,
                                    "email": email
                                ]) { error in
                                    if let error = error {
                                        print("Error storing user data: \(error.localizedDescription)")
                                        errorMessage = error.localizedDescription
                                    } else {
                                        print("User created and data stored successfully!")
                                        loginUser()
                                    }
                                }
                            }
                        }
                    }
                }) {
                    Text("Create Account")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding([.leading, .trailing], 20)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    func loginUser() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                // Handle login error
                errorMessage = error.localizedDescription
            } else {
                // Successfully logged in
                isLoggedIn = true // Trigger navigation or update UI
            }
        }
    }
}

struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        CreateAccountView()
    }
}
