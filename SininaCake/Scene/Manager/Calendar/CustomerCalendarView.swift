//
//  CustomerCalendarView.swift
//  SininaCake
//
//  Created by 이종원 on 1/15/24.
//

import SwiftUI
struct CustomerCalendarView: View {
    @Environment(\.sizeCategory) var sizeCategory
    @ObservedObject var calendarVM = ManagerCalendarViewModel()
    @State private var selectedDate: Date?
    @State var daysList = [[DateValue]]()
    @ObservedObject var orderData: OrderViewModel
    @State private var selectedTime: String = ""
    @State private var isTimePickerPresented: Bool = false
    
    let excludedDays: IndexSet = [0, 1]
    var testSchedule = Schedule(name: "", startDate: Date(), endDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date())
    var body: some View {
        VStack {
            HStack {
                CustomText(title: "픽업 날짜/시간", textColor: .black, textWeight: .semibold , textSize: 18)
                    .padding(.leading,(UIScreen.main.bounds.width) * 24/430)
                Spacer()
                CustomText(title: selectedTime, textColor: .black, textWeight: .semibold, textSize: 18)
                CustomText(title: dateToTime(orderData.orderItem.date), textColor: .black, textWeight: .semibold, textSize: 18)
                    .padding(.trailing,(UIScreen.main.bounds.width) * 24/430)
                    .onTapGesture {isTimePickerPresented.toggle()
                    }
                    .sheet(isPresented: $isTimePickerPresented, content: {
                        TimePickerView(selectedDate: Binding(
                            get: { selectedDate ?? Date() },
                            set: { selectedDate = $0 }
                        ))
                        .presentationDetents([.fraction(0.1)])
                    })
            }
            .scaledToFit()
            Spacer()
            Rectangle()
                .foregroundColor(.clear)
                .frame(width: 342, height: 441)
                .background(
                    ZStack {
                        Rectangle()
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 8)
                        VStack() {
                            headerView
                            Divider()
                                .frame(width: 302)
                            weekView
                            cardView
                            Divider()
                                .frame(width: 302)
                            bookingView
                                .padding([.horizontal,.vertical], 24)
                        }
                    }
                )
                .padding()
        }
    }
    
    private var headerView: some View {
        HStack {
            Spacer()
            Spacer()
            
            Button {
                calendarVM.monthOffset -= 1
                
            } label: {
                Image("angle-left")
            }
            .offset(x: 5)
            Text(calendarVM.month())
                .font(
                    Font.custom("Pretendard", fixedSize: 24)
                        .weight(.semibold))
                .kerning(0.6)
                .foregroundColor(Color(red: 0.45, green: 0.76, blue: 0.87))
                .minimumScaleFactor(0.7)
                .padding()
                .offset(x: 5)
            Button {
                calendarVM.monthOffset += 1
            } label: {
                Image("angle-right")
            }
            .offset(x: 5)
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // 부모 스택의 크기를 가득 채우도록 설정
    }
    
    private var weekView: some View {
        
        let days = ["  일", "월", "화", "수", "목", "금", "토"]
        
        return HStack(spacing:24) {
            ForEach(days.indices, id: \.self) { index in
                Text(days[index])
                    .font(.custom("Pretendard",fixedSize: 18))
                    .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.44))
                    .aspectRatio(contentMode: .fill)
                    .foregroundColor(index == 0 ? .red : (index == days.count - 1 ? Color(UIColor.customBlue) : .black))
            }
        }
        .minimumScaleFactor(0.1)
        .padding([.leading, .trailing], 10)
        .frame(width: UIScreen.main.bounds.width / 13)
        .frame(height: 40)
    }
    
    private var cardView: some View {
        VStack() {
            ForEach(daysList.indices, id: \.self) { i in
                HStack() {
                    ForEach(daysList[i].indices, id: \.self) { j in
                        CustomerCardView(value: $daysList[i][j], schedule: testSchedule, calendarVM:calendarVM, selectedDate: $selectedDate) { selectedDateValue in
                            handleDateClick(dateValue: selectedDateValue)
                        }
                    }
                }
                .minimumScaleFactor(0.1)
            }
        }
        .onDisappear()
        .onAppear() {
            calendarVM.monthOffset = Int(calendarVM.month()) ?? 0
            calendarVM.currentDate = calendarVM.getCurrentMonth()
            daysList = calendarVM.extractDate()
            calendarVM.loadDataFromFirestore()
            print("onappear - 캘린더뷰")
            for dv in calendarVM.dateValues {
                if calendarVM.currentDate.month == dv.date.month {
                    print("onchange - month : \(dv.date.month)")
                    for i in daysList.indices {
                        for j in daysList[i].indices {
                            if !daysList[i][j].isNotCurrentMonth && daysList[i][j].day == dv.day {
                                daysList[i][j] = dv
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: calendarVM.monthOffset) { _ in
            print("onchange - monthoffset, \(calendarVM.monthOffset)")
            calendarVM.currentDate = calendarVM.getCurrentMonth()
            daysList = calendarVM.extractDate()
            calendarVM.loadDataFromFirestore()
            for dv in calendarVM.dateValues {
                if calendarVM.currentDate.month == dv.date.month {
                    print("onchange - month : \(dv.date.month)")
                    for i in daysList.indices {
                        for j in daysList[i].indices {
                            if !daysList[i][j].isNotCurrentMonth && daysList[i][j].day == dv.day {
                                daysList[i][j] = dv
                            }
                        }
                    }
                }
            }
        }
        .onChange(of:calendarVM.dateValues) { _ in
            print("onchange - dataValues , \(calendarVM.dateValues.count)")
            for dv in calendarVM.dateValues {
                if calendarVM.currentDate.month == dv.date.month {
                    print("onchange - month : \(dv.date.month)")
                    for i in daysList.indices {
                        for j in daysList[i].indices {
                            if !daysList[i][j].isNotCurrentMonth && daysList[i][j].day == dv.day {
                                daysList[i][j] = dv
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: selectedDate) { newSelectedDate in
            if let newSelectedDate = newSelectedDate {
                orderData.orderItem.date = newSelectedDate
            }
        }
    }
    
    private var bookingView: some View {
        HStack() {
            Text("예약 가능")
                .frame(width: 70, height: 26)
                .foregroundColor(Color(red: 0.45, green: 0.76, blue: 0.87))
                .font(
                    Font.custom("Pretendard", fixedSize: 12)
                        .weight(.semibold))
                .overlay(
                    RoundedRectangle(cornerRadius: 45)
                        .inset(by: 0.5)
                        .stroke(Color(red: 0.45, green: 0.76, blue: 0.87), lineWidth: 1))
            Text("예약 마감")
                .frame(width: 70, height: 26)
                .foregroundColor(Color(red: 1, green: 0.27, blue: 0.27))
                .cornerRadius(45)
                .font(
                    Font.custom("Pretendard", fixedSize: 12)
                        .weight(.semibold))
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 45)
                        .inset(by: 0.5)
                        .stroke(Color(red: 1, green: 0.27, blue: 0.27), lineWidth: 1))
            Text("휴무")
                .frame(width: 70, height: 26)
                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                .cornerRadius(45)
                .font(
                    Font.custom("Pretendard", fixedSize: 12)
                        .weight(.semibold))
                .overlay(
                    RoundedRectangle(cornerRadius: 45)
                        .inset(by: 0.5)
                        .stroke(Color(red: 0.6, green: 0.6, blue: 0.6), lineWidth: 1))
        }
    }
    
    private func handleDateClick(dateValue: DateValue) {
        selectedDate = dateValue.date.withoutTime()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let dateString = dateFormatter.string(from: dateValue.date)
        selectedTime = dateString
        print("Filtered Orders for \(dateString)")
    }
}

struct CustomerCardView: View {
    @Binding var value: DateValue
    @State var schedule: Schedule
    @ObservedObject var calendarVM: ManagerCalendarViewModel
    @Binding var selectedDate: Date?
    @State private var showAlert: Bool = false
    var onDateClick: (DateValue) -> Void
    
    var body: some View {
        ZStack() {
            HStack {
                if value.day > 0 {
                    if value.isNotCurrentMonth {
                        Text("\(value.day)")
                            .font(.custom("Pretendard-SemiBold", fixedSize: 18))
                            .foregroundColor(Color(UIColor.customGray))
                            .padding([.leading, .bottom], 10)
                    } else {
                        if schedule.startDate.withoutTime() < value.date && value.date <= schedule.endDate
                        { Text("\(value.day)")
                                .font(.custom("Pretendard-SemiBold", fixedSize: 18))
                                .foregroundColor(value.isSelected ? Color(UIColor.customBlue) : (value.isSecondSelected ? Color(UIColor.customDarkGray) : Color(UIColor.customRed)))
                                .padding([.leading, .bottom], 10)
                                .onTapGesture {
                                    showAlert = true
                                }
                                .alert(isPresented: $showAlert) {
                                    Alert(
                                        title: Text("error"),
                                        message: Text("\(schedule.endDate.day + 1)일부터 예약이 가능합니다"),
                                        dismissButton: .default(Text("확인"))
                                    )
                                }
                        } else if schedule.startDate.withoutTime() == value.date {
                            Text("\(value.day)")
                                .font(.custom("Pretendard-SemiBold", fixedSize: 18))
                                .foregroundColor(.white)
                                .padding([.leading, .bottom], 10)
                                .background(Circle()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(Color(UIColor.customBlue))
                                    .offset(x:5.2,y:-3.7)
                                    .onTapGesture {
                                        showAlert = true
                                    }
                                    .alert(isPresented: $showAlert) {
                                        Alert(
                                            title: Text("error"),
                                            message: Text("\(schedule.endDate.day + 1)일부터 예약이 가능합니다"),
                                            dismissButton: .default(Text("확인"))
                                        )
                                    }
                                )
                        } else if schedule.startDate.withoutTime() > value.date {
                            Text("\(value.day)")
                                .font(.custom("Pretendard-SemiBold", fixedSize: 18))
                                .foregroundColor(value.isSelected ? Color(UIColor.customBlue) : (value.isSecondSelected ? Color(UIColor.customRed) : Color(UIColor.customDarkGray)))
                                .padding([.leading, .bottom], 10)
                                .onTapGesture {
                                    onDateClick(value)
                                }
                        }
                        else {
                            Text("\(value.day)")
                                .font(.custom("Pretendard-SemiBold", fixedSize: 18))
                                .foregroundColor((value.date.weekday == 1 || value.date.weekday == 2) ? (value.isSelected ? Color(UIColor.customBlue) : (value.isSecondSelected ? Color(UIColor.customRed) : Color(UIColor.customDarkGray))) : (value.isSelected ? Color(UIColor.customDarkGray) : (value.isSecondSelected ? Color(UIColor.customRed) : Color(UIColor.customBlue))))
                                .padding([.leading, .bottom], 10)
                                .onTapGesture {
                                    onDateClick(value)
                                }
                        }
                    }
                }
            }
        }
        .frame(width: UIScreen.main.bounds.width / 13)
        .frame(height: 40)
    }
}

struct TimePickerView: View {
    @Binding var selectedDate: Date
    var body: some View {
        DatePicker("", selection: $selectedDate, displayedComponents: [.date,.hourAndMinute])
            .datePickerStyle(CompactDatePickerStyle())
            .labelsHidden()
            .clipped()
    }
}

