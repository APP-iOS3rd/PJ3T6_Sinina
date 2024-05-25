//
//  ChatViewModel.swift
//  SininaCake
//
//  Created by  zoa0945 on 1/15/24.
//

import Foundation
import Firebase
import FirebaseStorage
import SwiftUI

class ChatViewModel: ObservableObject{
    static let shared = ChatViewModel()
    
    @Published var chatRooms = [ChatRoom]()
    @Published var messages = [String: [Message]?]() // key: 방 uuid, 메세지 배열
    @Published var lastMessageText = [String: String]()
    @Published var lastMessageId = ""
    @Published var lastMessageTimestamp = [String: String]()
    @Published var deviceToken = ""
    @Published var managerList: [String] = []
    @Published var managerDeviceToken: [String] = []
    @Published var chatRoom = ChatRoom(userEmail: "", id: "", lastMsg: "", lastMsgTime: Date(), imgURL: "", unreadMsgCnt: 0)
    
    var listeners = [ListenerRegistration]()
    var listener: ListenerRegistration?
    var db: Firestore!
    var ordersRef: CollectionReference!
    var unreadMsgCnt = 0
    
    init() {
        let settings = FirestoreSettings()
        
        Firestore.firestore().settings = settings
        
        db = Firestore.firestore()
        ordersRef = db.collection("Managers")
    }
    
    func fetchAllRooms(){
        listener?.remove()
        
        db.collection("chatRoom").getDocuments { (snapshot, error) in
            guard error == nil else { return }
            
            self.removeAll()
            
            for document in snapshot!.documents {
                if let data = try? document.data(as: ChatRoom.self) {
                    self.chatRooms.append(data)
                    
                    self.chatRooms.sort { room1, room2 in
                        if let time1 = room1.lastMsgTime, let time2 = room2.lastMsgTime {
                            return time1 > time2
                        } else if room1.lastMsgTime != nil {
                            return true
                        } else {
                            return false
                        }
                    }
                }
            }
        }
    }
    
    func removeAll(){
        self.chatRooms.removeAll()
        self.messages.removeAll()
        self.listeners.removeAll()
    }
    
    func fetchRoom(userEmail: String){
        db.collection("chatRoom").whereField("userEmail", isEqualTo: userEmail).getDocuments() { (snapshot, error) in
            guard error == nil else { print("fetch Room 에러 : \(error)")
                return }
            
            self.removeAll()
            
            for document in snapshot!.documents {
                if let data = try? document.data(as: ChatRoom.self) {
                    self.chatRooms.append(data)
                    self.startListening(chatRoom: data)
                }
            }
        }
    }
    
    func addChatRoom(chatRoom: ChatRoom) {
        try? db.collection("chatRoom").document(chatRoom.id).setData(from: chatRoom)
    }
    
    func startListening(chatRoom: ChatRoom) {
        listener = db.collection("chatRoom").document(chatRoom.id).collection("message").addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot, error == nil else {
                    print("Error: \(error!)")
                    return
                }

                snapshot.documentChanges.forEach { diff in
                    // 추가된 것만 따져서?
                    if (diff.type == .added || diff.type == .modified) {
                        if let data = try? diff.document.data(as: Message.self) {
                            
                            if self.messages[chatRoom.id] == nil {
                                self.messages[chatRoom.id] = [data] // 새 채팅 생김
                            } else {
                                self.messages[chatRoom.id]??.append(data) // 있던 방에 채팅 추가
                            }
                            
                            // 값이 업데이트가 된 경우
                            if diff.type == .modified {
                                self.messages[chatRoom.id] = self.updateChatRoom(message: (self.messages[chatRoom.id] ?? nil) ?? [], diff: data)
                            }
                            // 시간 순에 따라 버블 정렬
                            self.messages[chatRoom.id]??.sort { $0.timestamp < $1.timestamp }
                            
                            // 마지막 아이디 기억
                            if let id = self.messages[chatRoom.id]??.last?.id {
                                self.lastMessageId = id
                            }
                            
                            // 마지막 메세지 기억
                            if let lastMessageText = self.messages[chatRoom.id]??.last?.text {
                                self.lastMessageText[chatRoom.id] = lastMessageText
                            }
                            
                            // 마지막 메세지 시간 기억
                            if let lastMessageTimestamp = self.messages[chatRoom.id]??.last?.timestamp.formattedDate() {
                                self.lastMessageTimestamp[chatRoom.id] = lastMessageTimestamp
                            }
                        }
                    }
                }
        }
        listeners.append(listener!)
    }
    
    ///self.chattings의 채팅 내용을 업데이트 해주는 코드
    ///사용처 : 읽음처리
    private func updateChatRoom(message: [Message], diff: Message) -> [Message] {
        var tempMsg = message
        
        ///id로 찾아서 바꿔주기
        if let index = message.firstIndex(where: { $0.id == diff.id }) {
            tempMsg[index] = diff
        }
        
        return tempMsg
    }
    
    func sendMessage(chatRoom: ChatRoom?, message: Message) {
        if let chatRoom = chatRoom {
            try? db.collection("chatRoom").document(chatRoom.id)
                .collection("message").document(message.id).setData(from: message)
            
                self.unreadMsgCnt += 1 // 읽지 않은 메세지 +1

                try? db.collection("chatRoom").document(chatRoom.id).setData([
                "lastMsg": message.text,
                "lastMsgTime": message.timestamp,
                "unreadMsgCnt": unreadMsgCnt], merge: true)
        }
    }

    func sendMessageWithImage(chatRoom: ChatRoom, message: Message) {
        
        if let imageData = message.imageData {
            uploadImageToStorage(imageData: imageData) { result in
                
                switch result {
                case .success(let downloadURL):
                    var updatedMessage = message
                    updatedMessage.imageURL = downloadURL.absoluteString // imageURL 채움
                    
                    self.db.collection("chatRoom")
                        .document(chatRoom.id)
                        .collection("message")
                        .document(updatedMessage.id)
                        .setData(["id": updatedMessage.id,
                                  "userEmail": updatedMessage.userEmail,
                                  "text": updatedMessage.text,
                                  "timestamp": updatedMessage.timestamp,
                                  "imageURL": updatedMessage.imageURL,
                                  "viewed": false])
                    
                    self.unreadMsgCnt += 1
                    
                    try? self.db.collection("chatRoom").document(chatRoom.id).setData([
                        "lastMsg": "사진을 보냈습니다.",
                        "lastMsgTime": message.timestamp,
                        "unreadMsgCnt": self.unreadMsgCnt], merge: true)
                
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    func managerSendMessage(chatRoom: ChatRoom?, message: Message) {
        if let chatRoom = chatRoom {
            try? db.collection("chatRoom").document(chatRoom.id)
                .collection("message").document(message.id).setData(from: message)
            
                self.unreadMsgCnt = 0

                try? db.collection("chatRoom").document(chatRoom.id).setData([
                "lastMsg": message.text,
                "lastMsgTime": message.timestamp,
                "unreadMsgCnt": unreadMsgCnt], merge: true)
        }
    }
    
    func managerSendMessageWithImage(chatRoom: ChatRoom, message: Message) {
        
        if let imageData = message.imageData {
            uploadImageToStorage(imageData: imageData) { result in
                
                switch result {
                case .success(let downloadURL):
                    var updatedMessage = message
                    updatedMessage.imageURL = downloadURL.absoluteString // imageURL 채움
                    
                    self.db.collection("chatRoom")
                        .document(chatRoom.id)
                        .collection("message")
                        .document(updatedMessage.id)
                        .setData(["id": updatedMessage.id,
                                  "userEmail": updatedMessage.userEmail,
                                  "text": updatedMessage.text,
                                  "timestamp": updatedMessage.timestamp,
                                  "imageURL": updatedMessage.imageURL])
                    
                    self.unreadMsgCnt = 0
                    
                    try? self.db.collection("chatRoom").document(chatRoom.id).setData([
                        "lastMsg": "사진을 보냈습니다.",
                        "lastMsgTime": message.timestamp,
                        "unreadMsgCnt": self.unreadMsgCnt], merge: true)
                
                case .failure(let error):
                    print(error)
                }
            }
        }
    }

    func uploadImageToStorage(imageData: Data, completion: @escaping (Result<URL, Error>) -> Void) {
        
        let storageRef = Storage.storage().reference().child("chatImages/\(UUID().uuidString).jpg")
        storageRef.putData(imageData, metadata: nil) { metadata, error in
    
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                if let downloadURL = url {
                    completion(.success(downloadURL))
                }
            }
        }
    }
    
    func getDeviceToken(_ email: String) {
        let docRef = db.collection("Users").document(email)
        
        docRef.getDocument { [weak self] doc, error in
            if let error = error {
                print("FireStore Error: \(error.localizedDescription)")
                return
            }
            
            if let doc = doc, doc.exists, let self = self {
                let data = doc.data()
                if let data = data {
                    self.deviceToken = data["deviceToken"] as? String ?? ""
                }
            }
        }
    }
    
    @MainActor
    func fetchManagerList(completion: @escaping () -> Void) async {
        managerList = []
        
        do {
            let managers = try await ordersRef.document("Manager").getDocument()
            if let managerArr = managers.data()?["email"] as? [String] {
                    self.managerList = managerArr
            } else {
                print("Cannot found email in document")
            }
        } catch let error {
            print("Firebase error: \(error.localizedDescription)")
        }
        completion()
    }
    
    func getManagerDeviceToken(_ emails: [String]) {
        managerDeviceToken = []
        
        for email in emails {
            let docRef = db.collection("Users").document(email)
            
            docRef.getDocument { [weak self] doc, error in
                if let error = error {
                    print("FireStore Error: \(error.localizedDescription)")
                    return
                }
                
                if let doc = doc, doc.exists, let self = self {
                    let data = doc.data()
                    if let data = data {
                        let token = data["deviceToken"] as? String ?? ""
                        self.managerDeviceToken.append(token)
                    }
                }
            }
        }
    }
    
    func getChatRoom(_ email: String) {
        let docRef = db.collection("chatRoom").document(email)
        
        docRef.getDocument { [weak self] doc, error in
            if let error = error {
                print("FireStore Error: \(error.localizedDescription)")
                return
            }
            
            if let doc = doc, doc.exists, let self = self {
                let data = doc.data()
                if let data = data {
                    let id: String = data["id"] as? String ?? ""
                    let userEmail: String = data["userEmail"] as? String ?? ""
                    let lastMsgTime: Timestamp = data["lastMsgTime"] as? Timestamp ?? Timestamp()
                    let lastMsg: String = data["lastMsg"] as? String ?? ""
                    let unreadMsgCnt: Int = data["unreadMsgCnt"] as? Int ?? 0
                    let imgURL: String = data["imgURL"] as? String ?? ""
                    
                    let chatRoom = ChatRoom(userEmail: userEmail, id: id, lastMsg: lastMsg, lastMsgTime: lastMsgTime.dateValue(), imgURL: imgURL, unreadMsgCnt: unreadMsgCnt)
                    
                    self.chatRoom = chatRoom
                }
            }
        }
    }
}

