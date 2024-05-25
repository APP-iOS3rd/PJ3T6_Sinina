//
//  ChatView2.swift
//  SininaCake
//
//  Created by 김수비 on 2/14/24.
//

import SwiftUI
import Kingfisher

struct CustomerChatView: View {
    
    @ObservedObject var chatVM = ChatViewModel.shared
    @ObservedObject var loginVM = LoginViewModel.shared
    @StateObject var fcmServerAPI = FCMServerAPI()
    @State var chatText = ""
    @State var room: ChatRoom
    
    @State var isClicked = false
    @State var imgUrl: String = ""
    
    @State private var isChatTextEmpty = true
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: 통합 뷰
    var body: some View {
        VStack {
            messagesView
            chatBottomBar
        }
        .onAppear {
            Task {
                await chatVM.fetchManagerList {
                    chatVM.getManagerDeviceToken(chatVM.managerList)
                }
            }
        }
    }
    
    // MARK: 메세지 창 띄우는 뷰
    private var messagesView: some View {
        NavigationView {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        if chatVM.messages[room.id] != nil {
                            ForEach(chatVM.messages[room.id]!!, id: \.self) { msg in
                                if loginVM.loginUserEmail == msg.userEmail {
                                    blueMessageBubble(message: msg)
                                        .id(msg.id)
                                } else {
                                    grayMessageBubble(message: msg)
                                        .id(msg.id)
                                }
                            }
                            .background(Color.clear)
                            .onChange(of: chatVM.lastMessageId){ id in
                                withAnimation {
                                    proxy.scrollTo(id, anchor: .bottom)
                                }
                            }
                            .onAppear(){
                                withAnimation {
                                    proxy.scrollTo(chatVM.lastMessageId, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    chatVM.fetchRoom(userEmail: room.userEmail)
                }
            }
            .navigationTitle("시니나케이크")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Image("angle-left-black")
                    })
                }
            }
        }
    }
    
    //MARK: 채팅 치는 뷰
    private var chatBottomBar: some View {
        HStack(spacing: 10) {
            Button {
                isImagePickerPresented.toggle()
                
            } label: {
                Image(systemName: "plus")
                    .foregroundColor(Color(.customBlue))
                    .frame(width: 24, height: 24)
                    .padding(10)
                    .background(.white)
                    .cornerRadius(45)
            }
            .sheet(isPresented: $isImagePickerPresented){
                ImagePicker(selectedImage: $selectedImage)
            }
            
            ZStack {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .onAppear(){
                            isChatTextEmpty = false
                        }
                } else {
                    TextField("", text: $chatText)
                        
                        .background(Color(.customLightGray))
                        .onChange(of: chatText){ value in
                            isChatTextEmpty = value.isEmpty
                        }
                }
            }
            
            Button {
                if let selectedImage = selectedImage {
                    if let image = selectedImage.jpegData(compressionQuality: 1){
                        let msg = Message(imageData: image, imageURL: "", userEmail: loginVM.loginUserEmail ?? "", timestamp: Date(), viewed: false)
                        
                        chatVM.sendMessageWithImage(chatRoom: room, message: msg)
                        for token in chatVM.managerDeviceToken {
                            fcmServerAPI.sendFCM(deviceToken: token, title: room.userEmail ,body: "사진")
                        }
                    }
                    self.selectedImage = nil
                    
                } else {
                    let msg = Message(text: chatText, userEmail: loginVM.loginUserEmail ?? "", timestamp: Date(), viewed: false)
                    
                    chatVM.sendMessage(chatRoom: room, message: msg)
                    for token in chatVM.managerDeviceToken {
                        fcmServerAPI.sendFCM(deviceToken: token, title: room.userEmail, body: chatText)
                    }
                }
                
                chatText = ""
                isChatTextEmpty = true
                
            } label: {
                Image(systemName: "paperplane")
                    .foregroundColor(isChatTextEmpty ? Color(.customDarkGray) : .white)
                    .frame(width: 24, height: 24)
                    .padding(10)
                    .background(isChatTextEmpty ? Color(.customGray) : Color(.customBlue))
                    .cornerRadius(45)
            }
            .disabled(isChatTextEmpty)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 5)
        .background(Color(.customLightGray))
        .cornerRadius(45)
        .padding()
    }
    
    // MARK: - 파란 말풍선
    private func blueMessageBubble(message: Message) -> some View {
        HStack {
            // MARK: - 메세지 읽지 않은 경우
            if message.viewed == false {
                CustomText(title: "1", textColor: .customBlue, textWeight: .regular, textSize: 12)
            }
            
            CustomText(title: message.timestamp.formattedDate(), textColor: .customDarkGray, textWeight: .regular, textSize: 12 )
            
            if let imageURL = message.imageURL {
                AsyncImage(url: URL(string: imageURL), content: { image in
                    image
                        .resizable()
                        .frame(idealWidth: 300, idealHeight: 300, alignment: .trailing)
                },
                           placeholder: {
                    ProgressView()
                })
                .onTapGesture {
                    KingfisherManager.shared.retrieveImage(with: URL(string: imageURL)!) { result in
                        switch result {
                        case .success(let value):
                            imgUrl = value.source.url?.absoluteString ?? ""
                            isClicked.toggle()
                            
                        case .failure:
                            break
                        }
                    }
                }
                .fullScreenCover(isPresented: $isClicked, content: {
                    ZStack(alignment: .topTrailing) {
                        KFImage(URL(string: imgUrl))
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                        
                        CustomXButton(isClicked: $isClicked)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(UIScreen.UIWidth(8))
                    }
                    .gesture(DragGesture(minimumDistance: 20)
                        .onEnded({ value in
                            if value.translation.height > 100 {
                                isClicked.toggle()
                            }
                        })
                    )
                })
                .frame(width: UIScreen.UIWidth(185),
                       height: UIScreen.UIHeight(185))
                .clipShape(.rect(cornerRadius: 12))
                
            } else {
                Text("\(message.text ?? "")")
                    .padding()
                    .frame(idealWidth: 300)
                    .font(.custom("Pretendard", fixedSize: 16))
                    .fontWeight(.regular)
                    .foregroundStyle(.white)
                    .background(Color(.customBlue))
                    .cornerRadius(30)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 10)
    }
    
    // MARK: - 회색 말풍선
    private func grayMessageBubble(message: Message) -> some View {
        HStack {
            if let imageURL = message.imageURL {
                AsyncImage(url: URL(string: imageURL), content: { image in
                    image
                        .resizable()
                        .frame(idealWidth: 300, idealHeight: 300, alignment: .trailing)
                },
                           placeholder: {
                    ProgressView()
                })
                .onTapGesture {
                    KingfisherManager.shared.retrieveImage(with: URL(string: imageURL)!) { result in
                        switch result {
                        case .success(let value):
                            imgUrl = value.source.url?.absoluteString ?? ""
                            isClicked.toggle()
                            
                        case .failure:
                            break
                        }
                    }
                }
                .fullScreenCover(isPresented: $isClicked, content: {
                    ZStack(alignment: .topTrailing) {
                        KFImage(URL(string: imgUrl))
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                        
                        CustomXButton(isClicked: $isClicked)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(UIScreen.UIWidth(8))
                    }
                    .gesture(DragGesture(minimumDistance: 20)
                        .onEnded({ value in
                            if value.translation.height > 100 {
                                isClicked.toggle()
                            }
                        })
                    )
                })
                .frame(width: UIScreen.UIWidth(185),
                       height: UIScreen.UIHeight(185))
                .clipShape(.rect(cornerRadius: 12))
                
            } else {
                Text("\(message.text ?? "")")
                    .padding()
                    .frame(idealWidth: 300)
                    .font(.custom("Pretendard", fixedSize: 16))
                    .fontWeight(.regular)
                    .foregroundStyle(.black)
                    .background(Color(.customLightGray))
                    .cornerRadius(30)
            }
            
            CustomText(title: message.timestamp.formattedDate(), textColor: .customDarkGray, textWeight: .regular, textSize: 12)
            
//            if message.viewed == false {
//                CustomText(title: "1", textColor: .customBlue, textWeight: .regular, textSize: 12)
//            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
    }
}

//#Preview {
//    CustomerChatView(room: ChatRoom(userEmail: "20subi@gmail.com", id: "20subi@gmail.com", lastMsg: nil, lastMsgTime: nil, imgURL: ""))
//}
