//
//  LoginViewModel.swift
//  SininaCake
//
//  Created by  zoa0945 on 1/15/24.
//

import AuthenticationServices
import CryptoKit
import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import KakaoSDKUser

class LoginViewModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
    @Published var isLoggedin: Bool = false
    var currentNonce: String?
    
    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      var randomBytes = [UInt8](repeating: 0, count: length)
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
      if errorCode != errSecSuccess {
        fatalError(
          "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
        )
      }

      let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

      let nonce = randomBytes.map { byte in
        // Pick a random character from the set, wrapping around if needed.
        charset[Int(byte) % charset.count]
      }

      return String(nonce)
    }
    
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
      }.joined()

      return hashString
    }
    
    /// 애플 로그인
    @available(iOS 13, *)
    func startSignInWithAppleFlow() {
      let nonce = randomNonceString()
      currentNonce = nonce
      let appleIDProvider = ASAuthorizationAppleIDProvider()
      let request = appleIDProvider.createRequest()
      request.requestedScopes = [.fullName, .email]
      request.nonce = sha256(nonce)

      let authorizationController = ASAuthorizationController(authorizationRequests: [request])
      authorizationController.delegate = self
      authorizationController.performRequests()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
          guard let nonce = currentNonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
          }
          guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetch identity token")
            return
          }
          guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            return
          }
          // Initialize a Firebase credential, including the user's full name.
          let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                            rawNonce: nonce,
                                                            fullName: appleIDCredential.fullName)
          // Sign in with Firebase.
        
          Auth.auth().signIn(with: credential) { (authResult, error) in
            if error != nil {
              // Error. If error.code == .MissingOrInvalidNonce, make sure
              // you're sending the SHA256-hashed nonce as a hex string with
              // your request to Apple.
              print(error?.localizedDescription)
              return
            }
              self.isLoggedin = true
          }
        }
      }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
    }
  
    // MARK: - 카카오 로그인
     /// 카카오 로그인
    func handleKakaoLogin() {
        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk {(oauthToken, error) in
                if let error = error {
                    print(error)
                } else {
                    print("loginWithKakaoTalk() success.")
                    self.getAndStoreKakaoUserInfo()
                    self.isLoggedin = true
                }
            }
        } else {
            UserApi.shared.loginWithKakaoAccount {(oauthToken, error) in
                if let error = error {
                    print(error)
                } else {
                    print("loginWithKakaoAccount() success.")
                    //do something
//                    _ = oauthToken
                    self.getAndStoreKakaoUserInfo()
                    self.isLoggedin = true
                }
            }
        }
    }
    
    // MARK: - 구글 로그인
    /// 구글 로그인
    func handleGoogleLogin() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(withPresenting: Utilities.rootViewController) { result, error in
            
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString else { return }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                guard let user = result?.user else { return }
                print(user)
                self.isLoggedin = true
            }
        }
    }
    
    // MARK: - 카카오 유저 정보 획득
    func getAndStoreKakaoUserInfo() {
//        var nickName: String
//        var email: String
//        var imgURL: String
        
        UserApi.shared.me() {(user, error) in
            if let error = error {
                print(error)
            }
            else {
                print("me() success.")
//                nickName = user?.kakaoAccount?.profile?.nickname ?? ""
//                email = user?.kakaoAccount?.email ?? ""
//                imgURL = user?.kakaoAccount?.profile?.thumbnailImageUrl?.absoluteString ?? ""
                Task {
                    await self.addUserInfoToFirestore(email: user?.kakaoAccount?.email ?? "", 
                                                      imgURL: user?.kakaoAccount?.profile?.thumbnailImageUrl?.absoluteString ?? "",
                                                      userName: user?.kakaoAccount?.profile?.nickname ?? "")
                }
            }
        }
//        return (nickName, email, imgURL)
    }
    
    // MARK: - 유저 정보 파이어스토어에 저장
    func addUserInfoToFirestore(email: String, imgURL: String, userName: String) async {

        let db = Firestore.firestore()
        
        do {
          try await db.collection("Users").document(email).setData([
            "email": email,
            "userName": userName,
            "imgURL": imgURL
          ], merge: true)
          print("Document successfully written!")
        } catch {
          print("Error writing document: \(error)")
        }
    }
}
