//
//  MapView.swift
//  SininaCake
//
//  Created by 이종원 on 1/15/24.
//

import SwiftUI
import NMapsMap

struct MapView: View {
    var body: some View {
        VStack {
            CustomText(title: "찾아오시는 길", textColor: .black, textWeight: .semibold, textSize: 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 24)
            
            Spacer()
                .frame(height: 40)
            
            NaverMap(coord: (37.6550100, 127.069713))
                .foregroundColor(.clear)
                .frame(width: UIScreen.main.bounds.size.width * (382/430), height: UIScreen.main.bounds.size.height * (435/932))
                .clipShape(
                    .rect(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 12)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 8)
                .padding(.vertical, -16)
            
            AddressView()
        }
    }
}

struct AddressView: View {
    var body: some View {
        VStack(alignment: .leading) {
            CustomText(title: "시니나 케이크", textColor: .black, textWeight: .semibold, textSize: 18)
            
            CustomText(title: "서울 노원구 노원로30길 44 1층", textColor: .customDarkGray, textWeight: .semibold, textSize: 16)
        }
        .foregroundColor(.clear)
        .padding(.horizontal, 24)
        .frame(width: UIScreen.main.bounds.size.width * (382/430), height: UIScreen.main.bounds.size.height * (100/932), alignment: .leading)
        .background(.white)
        .clipShape(
            .rect(topLeadingRadius: 0, bottomLeadingRadius: 12, bottomTrailingRadius: 12, topTrailingRadius: 0)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 8)
    }
}

struct NaverMap: UIViewRepresentable {
    var coord: (Double, Double)
  
    func makeUIView(context: Context) -> NMFNaverMapView {
        let view = NMFNaverMapView()
        view.showZoomControls = false
        view.mapView.positionMode = .direction
        view.mapView.zoomLevel = 19
        return view
    }
    
    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
        let coord = NMGLatLng(lat: coord.0, lng: coord.1)
        let cameraUpdate = NMFCameraUpdate(scrollTo: coord)
        cameraUpdate.animation = .fly
        cameraUpdate.animationDuration = 1
        uiView.mapView.moveCamera(cameraUpdate)
        
        let marker = NMFMarker()
        
        marker.position = coord
        marker.mapView = uiView.mapView
        marker.width = 40
        marker.height = 50
        marker.iconImage = NMF_MARKER_IMAGE_BLACK
        marker.iconTintColor = .customBlue
    }
}

#Preview {
    MapView()
}
