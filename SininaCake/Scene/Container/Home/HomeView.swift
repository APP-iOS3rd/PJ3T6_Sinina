//
//  HomeView.swift
//  SininaCake
//
//  Created by  zoa0945 on 1/15/24.
//

import SwiftUI
import KakaoSDKAuth

//enum Tab: String, CaseIterable {
//    case chat = ""
//    case home = ""
//    case profile = ""
//}

struct HomeView: View {
    @StateObject var homeVM = HomeViewModel()
    
    var body: some View {
        // TODO: MyPage로 이동 예정
        ScrollView {
            VStack {
                InstagramView()
                MapView()
            }
        }
    }
}


#Preview {
    HomeView()
}