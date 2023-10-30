//
//  LoginViewModel.swift
//  MultiAuthPage
//
//  Created by Yusuf Karan on 28.10.2023.
//

import SwiftUI
import Firebase

class LoginViewModel: ObservableObject {
    //MARK: View Properties
    @Published var mobileNo: String = ""
    @Published var otpCode: String = ""
    
    @Published var CLIENT_CODE: String = ""
    @Published var showOTPField: Bool = false
    
    // MARK: Error Properties
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: Firebase API's
    func getOTPCode(){
        Task{
            do{
                // MARK: Disable it when testing with Real Device
                Auth.auth().settings?.isAppVerificationDisabledForTesting = true
                
                let code = try await PhoneAuthProvider.provider().verifyPhoneNumber("+\(mobileNo)", uiDelegate: nil)
                await MainActor.run(body: {
                    CLIENT_CODE = code
                })
                
            }catch{
                await handleError(error: error)
            }
        }
    }
    
    func verifyOTPCode() {
        Task{
            do{
                let credential = PhoneAuthProvider.provider().credential(withVerificationID: CLIENT_CODE, verificationCode: otpCode)
                
                try await Auth.auth().signIn(with: credential)
                
                // MARK: User Logged in Succesfuly
                print("Success!")
            }catch{
                await handleError(error: error)
            }
        }
    }
    
    // MARK: Handling Error
    func handleError(error: Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}

// MARK: Extensions
extension UIApplication{
    func closeKeyboard(){
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
