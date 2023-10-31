//
//  LoginViewModel.swift
//  MultiAuthPage
//
//  Created by Yusuf Karan on 28.10.2023.
//

import SwiftUI
import Firebase
import CryptoKit
import AuthenticationServices
import GoogleSignIn

class LoginViewModel: ObservableObject {
  //MARK: View Properties
  @Published var mobileNo: String = ""
  @Published var otpCode: String = ""
  
  @Published var CLIENT_CODE: String = ""
  @Published var showOTPField: Bool = false
  
  // MARK: Error Properties
  @Published var showError: Bool = false
  @Published var errorMessage: String = ""
  
  // MARK: Log status
  @AppStorage("log_status") var logStatus: Bool = false
  
  // MARK: Apple Sign In Properties
  @Published var nonce : String = ""
  
  // MARK: Firebase API's
  func getOTPCode(){
    UIApplication.shared.closeKeyboard()
    Task{
      do{
        // MARK: Disable it when testing with Real Device
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
        
        let code = try await PhoneAuthProvider.provider().verifyPhoneNumber("+\(mobileNo)", uiDelegate: nil)
        await MainActor.run(body: {
          CLIENT_CODE = code
          // MARK: Enabling OTP Field When It's Success
          withAnimation(.easeInOut){showOTPField = true}
        })
        
      }catch{
        await handleError(error: error)
      }
    }
  }
  
  func verifyOTPCode() {
    UIApplication.shared.closeKeyboard()
    Task{
      do{
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: CLIENT_CODE, verificationCode: otpCode)
        
        try await Auth.auth().signIn(with: credential)
        
        // MARK: User Logged in Succesfuly
        print("Success!")
        await MainActor.run(body: {
          withAnimation(.easeInOut){logStatus = true}
        })
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
  
  func appleAuthenticate(credential: ASAuthorizationAppleIDCredential){
    guard let token = credential.identityToken else {
      print("error with token")
      return
    }
    
    guard let tokenString = String(data: token, encoding: .utf8) else {
      print("error with token")
      return
    }
    
    let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
    Auth.auth().signIn(with: firebaseCredential) { (result, err) in
      if let error = err {
        print(error.localizedDescription)
        return
      }
      
      print("login in success")
      withAnimation(.easeInOut){self.logStatus = true}
    }
  }
  
  //MARK: Logging Google User Into Firebase
  func logGoogleUser(user: GIDGoogleUser){
    Task{
        do{
          guard let idToken = user.authentication.idToken else{return}
          
          let accesToken = user.authentication.accessToken
          let credential = OAuthProvider.credential(withProviderID: idToken, accessToken: accesToken)
          
          try await Auth.auth().signIn(with: credential)
          
          print("Success Google Login")
          await MainActor.run(body: {
            withAnimation(.easeInOut){self.logStatus = true}
          })
        }catch{
          await handleError(error: error)
        }
    }
  }
}
  
  
// MARK: Extensions
extension UIApplication{
  func closeKeyboard(){
    sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
  
  func rootController()->UIViewController {
    guard let window = connectedScenes.first as? UIWindowScene else{return .init()}
    guard let viewcontroller = window.windows.last?.rootViewController else{return .init()}
    
    return viewcontroller
  }
}
  
  func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
      return String(format: "@02x", $0)
    }.joined()
    
    return hashString
  }
  
  func randomNonceString(lenght : Int = 32) -> String {
    precondition(lenght > 0)
    let charset : Array<Character> = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = lenght
    
    while remainingLength > 0 {
      let randoms: [UInt8] = (0 ..< 16).map { _ in
        var random: UInt8 = 0
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
        if errorCode != errSecSuccess {
          fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        return random
      }
      
      randoms.forEach { random in
        if remainingLength == 0 {
          result
        }
        
        if random < charset.count {
          result.append(charset[Int(random)])
          remainingLength -= 1
        }
      }
    }
    return result
  }

