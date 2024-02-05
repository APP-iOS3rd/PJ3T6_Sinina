//
//  OrderDetailView.swift
//  SininaCake
//
//  Created by  zoa0945 on 1/15/24.
//

import SwiftUI

struct OrderDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var orderItem: OrderItem
    @State var isButtonActive = true
    
    var body: some View {
        var statusTitle: (String, UIColor) {
            switch orderItem.status {
            case .assign:
                return ("승인 주문건 현황", .customBlue)
            case .notAssign:
                return ("미승인 주문건 현황", .customLightgray)
            case .complete:
                return ("완료 주문건 현황", .black)
            }
        }
        
        ScrollView {
            VStack {
                HStack {
                    Image(systemName: "checkmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(Color(statusTitle.1))
                    CustomText(title: statusTitle.0, textColor: .black, textWeight: .semibold, textSize: 18)
                    Spacer()
                }
                .padding(.leading, 24)
                .padding(.top, 40)
                
                Spacer()
                    .frame(height: 42)
                
                OrderInfoView(orderItem: $orderItem)
                
                DividerView()
                
                CakeInfoView(orderItem: $orderItem)
                
                Spacer()
                    .frame(height: 18)
                
                PhotoView(orderItem: $orderItem)
                
                DividerView()
                
                PriceView(orderItem: $orderItem, toggle: $isButtonActive)
            }
        }
        .navigationBarBackButtonHidden()
        .navigationTitle("주문현황")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { presentationMode.wrappedValue.dismiss() }, label: {
                    Image(systemName: "chevron.backward")
                        .foregroundStyle(Color.black)
                })
            }
        }
        AssignButton(toggle: $isButtonActive)
    }
}

struct DividerView: View {
    var body: some View {
        Spacer()
            .frame(height: 32)
        
        Divider()
        
        Spacer()
            .frame(height: 32)
    }
}

struct OrderInfoView: View {
    @Binding var orderItem: OrderItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 18) {
                CustomText(title: "픽업날짜", textColor: .customGray, textWeight: .semibold, textSize: 16)
                CustomText(title: "픽업시간", textColor: .customGray, textWeight: .semibold, textSize: 16)
                CustomText(title: "이름", textColor: .customGray, textWeight: .semibold, textSize: 16)
                CustomText(title: "휴대전화", textColor: .customGray, textWeight: .semibold, textSize: 16)
            }
            
            Spacer()
                .frame(width: 63)
            
            VStack(alignment: .leading, spacing: 18) {
                CustomText(title: dateToString(orderItem.date), textColor: .black, textWeight: .semibold, textSize: 16)
                CustomText(title: dateToTime(orderItem.date), textColor: .black, textWeight: .semibold, textSize: 16)
                CustomText(title: orderItem.name, textColor: .black, textWeight: .semibold, textSize: 16)
                CustomText(title: orderItem.phoneNumber, textColor: .black, textWeight: .semibold, textSize: 16)
            }
            
            Spacer()
        }
        .padding(.leading, 24)
    }
}

struct CakeInfoView: View {
    @Binding var orderItem: OrderItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 18) {
                CustomText(title: "사이즈", textColor: .customGray, textWeight: .semibold, textSize: 16)
                CustomText(title: "시트(빵)", textColor: .customGray, textWeight: .semibold, textSize: 16)
                CustomText(title: "속크링", textColor: .customGray, textWeight: .semibold, textSize: 16)
                CustomText(title: "문구/글씨 색상", textColor: .customGray, textWeight: .semibold, textSize: 16)
            }
            
            Spacer()
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 18) {
                CustomText(title: orderItem.cakeSize, textColor: .black, textWeight: .semibold, textSize: 16)
                CustomText(title: orderItem.sheet, textColor: .black, textWeight: .semibold, textSize: 16)
                CustomText(title: orderItem.cream, textColor: .black, textWeight: .semibold, textSize: 16)
                CustomText(title: orderItem.text, textColor: .black, textWeight: .semibold, textSize: 16)
            }
            
            Spacer()
        }
        .padding(.leading, 24)
    }
}

struct PhotoView: View {
    @Binding var orderItem: OrderItem
    var columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
    let imageWidth = (UIScreen.main.bounds.width - 60) / 2
    
    var body: some View {
        VStack {
            HStack {
                CustomText(title: "사진", textColor: .customGray, textWeight: .semibold, textSize: 16)
                Spacer()
            }
            
            Spacer()
                .frame(height: 24)
            
            LazyVGrid(columns: columns, spacing: 34) {
                ForEach((0..<orderItem.imageURL.count), id: \.self) { i in
                    Image(systemName: orderItem.imageURL[i])
                        .resizable()
                        .frame(width: imageWidth - 20, height: imageWidth - 20)
                        .scaledToFit()
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.customLightgray))
                                .frame(width: imageWidth, height: imageWidth)
                        )
                }
            }
            
            Spacer()
                .frame(height: 28)
            
            HStack {
                CustomText(title: "추가 요청 사항", textColor: .customGray, textWeight: .semibold, textSize: 16)
                Spacer()
                    .frame(width: 26)
                CustomText(title: orderItem.comment, textColor: .black, textWeight: .semibold, textSize: 16)
                Spacer()
            }
        }
        .padding(.leading, 24)
        .padding(.trailing, 24)
    }
}

struct PriceView: View {
    @Binding var orderItem: OrderItem
    @Binding var toggle: Bool
    @State var totalPrice = 0
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    var body: some View {
        VStack {
            HStack {
                CustomText(title: "총 예상금액", textColor: .customGray, textWeight: .semibold, textSize: 16)
                Spacer()
                    .frame(width: 45)
                CustomText(title: intToString(orderItem.expectedPrice), textColor: .black, textWeight: .semibold, textSize: 16)
                Spacer()
            }
            
            // 미승인 주문 건
            HStack {
                CustomText(title: "총 확정금액", textColor: .customGray, textWeight: .semibold, textSize: 16)
                Spacer()
                    .frame(width: 24)
                HStack {
                    TextField("", value: $totalPrice, formatter: formatter)
                        .padding()
                        .background(Color(.white))
                        .keyboardType(.decimalPad)
                    Button(action: { toggle = false }, label: {
                        CustomText(title: "등록", textColor: .white, textWeight: .semibold, textSize: 16)
                    })
                    .frame(width: 94, height: 55)
                    .background(Color(.customBlue))
                    .cornerRadius(27.5)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 27.5)
                        .stroke(Color(.customLightgray))
                )
                Spacer()
            }
        }
        .padding(.leading, 24)
        .padding(.trailing, 24)
    }
}

struct AssignButton: View {
    @Binding var toggle: Bool
    
    var body: some View {
        CustomButton(action: { print("승인") }, title: "승인하기", titleColor: .white, backgroundColor: .customBlue, leading: 24, trailing: 24)
            .padding(.top, 29)
            .disabled(toggle)
    }
}

private func intToString(_ price: Int) -> String {
    let priceString = String(price)
    var result = ""
    var count = 0
    
    for str in priceString.reversed() {
        result += String(str)
        count += 1
        if count % 3 == 0 {
            result += ","
        }
    }
    
    return result.reversed() + "원"
}

private func dateToString(_ date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko-KR")
    dateFormatter.dateFormat = "yyyy/MM/dd(E)"
    
    let dateString = dateFormatter.string(from: date)
    return dateString
}

private func dateToTime(_ date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm"
    
    let timeString = dateFormatter.string(from: date)
    return timeString
}
