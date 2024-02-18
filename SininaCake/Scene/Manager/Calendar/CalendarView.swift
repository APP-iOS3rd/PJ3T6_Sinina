//
//  CalendarView.swift
//  SininaCake
//
//  Created by  zoa0945 on 11/12/23.
//
import SwiftUI
struct CalendarView: View {
    
    @Environment(\.sizeCategory) var sizeCategory
    @ObservedObject var dateValueVM = DateValueViewModel()
    @StateObject var orderListVM = OrderListViewModel()
    @StateObject var orderDateVM = OrderDateViewModel()
    
    
    var testSchedule = Schedule(name: "", startDate: Date(), endDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date())
    @State var currentDate = Date()
    @State var daysList = [[DateValue]]()
    //화살표 클릭에 의한 월 변경 값
    @State var monthOffset = 0
    @State var edit: Bool = false
    @State var getData: Bool = false
    var body: some View {
        
        ScrollView {
            Spacer()
            Spacer()
            VStack() {
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
            }
            VStack {
                if edit && getData {
                    ListView(orderData: orderListVM.assignOrderData, title: "주문 내역", titleColor: .black)
                    
                }
            }
            .onAppear {
                orderListVM.fetchData()
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Spacer()
            Spacer()
            
            Button {
                monthOffset -= 1
                
            } label: {
                Image("angle-left")
            }
            .offset(x: 8)
            Text(month())
                .font(
                    Font.custom("Pretendard", fixedSize: 24)
                        .weight(.semibold))
                .kerning(0.6)
                .foregroundColor(Color(red: 0.45, green: 0.76, blue: 0.87))
                .minimumScaleFactor(0.7)
                .padding()
                .offset(x: 8)
            Button {
                monthOffset += 1
            } label: {
                Image("angle-right")
            }
            .offset(x: 8)
            
            Spacer()
            
            
            Button {
                print("편집 작동, \(edit)")
                edit.toggle()
                getData.toggle()
            } label: {
                Image(systemName:"list.clipboard.fill")
                    .foregroundColor(Color(.customBlue))
            }
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
                        CardView(value: $daysList[i][j], schedule: testSchedule, dateValueVM:dateValueVM,isReadOnly: false, edit: $edit, getData: $getData)
                        
                    }
                }
                .minimumScaleFactor(0.1)
            }
        }
        .onDisappear()
        .onChange(of: monthOffset) { _ in
            // updating Month...
            print("onchange - monthoffset, \(monthOffset)")
            currentDate = getCurrentMonth()
            daysList = extractDate()
            dateValueVM.loadDataFromFirestore()
            for dv in dateValueVM.dateValues {
                if currentDate.month == dv.date.month {
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
        .onChange(of:dateValueVM.dateValues) { _ in
            print("onchange - dataValues , \(dateValueVM.dateValues.count)")
            for dv in dateValueVM.dateValues {
                if currentDate.month == dv.date.month {
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
        .onAppear() {
            
            monthOffset = Int(month()) ?? 0
            currentDate = getCurrentMonth()
            daysList = extractDate()
            dateValueVM.loadDataFromFirestore()
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
    //현재 날짜 년도
    func year() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "YYYY"
        
        return formatter.string(from: currentDate)
    }
    
    //현재 날짜 월
    func month() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "MMMM"
        
        return formatter.string(from: currentDate)
    }
    
    // 현재 월 로드, monthOffset 값에 변경이 있을 경우 해당 월 로드
    func getCurrentMonth() -> Date {
        let calendar = Calendar.current
        
        guard let currentMonth = calendar.date(byAdding: .month, value: self.monthOffset, to: Date()) else {
            return Date()
        }
        return currentMonth
    }
    //현재 월의 일수 로드 (달력 남은 공간을 채우기 위한 이전달 및 다음달 일수 포함)
    func extractDate() -> [[DateValue]] {
        let calendar = Calendar.current
        
        let currentMonth = getCurrentMonth()
        
        var days = currentMonth.getAllDates().compactMap { date -> DateValue in
            
            let day = calendar.component(.day, from: date)
            
            return DateValue(day: day, date: date)
        }
        //이전달 일수로 남은 공간 채우기
        let firstWeekDay = calendar.component(.weekday, from: days.first?.date ?? Date())
        
        let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: days.first?.date ?? Date())
        
        let prevMonthLastDay = prevMonthDate?.getLastDayInMonth() ?? 0
        
        for i in 0..<firstWeekDay - 1 {
            days.insert(DateValue(day: prevMonthLastDay - i, date: calendar.date(byAdding: .day, value: -1, to: days.first?.date ?? Date()) ?? Date(), isNotCurrentMonth: true), at: 0)
        }
        //다음달 일수로 남은 공간 채우기
        let lastWeekDay = calendar.component(.weekday, from: days.last?.date ?? Date())
        
        let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: days.first?.date ?? Date())
        
        let nextMonthFirstDay = nextMonthDate?.getFirstDayInMonth() ?? 0
        
        for i in 0..<7 - lastWeekDay {
            days.append(DateValue(day: nextMonthFirstDay + i, date: calendar.date(byAdding: .day, value: 1, to: days.last?.date ?? Date()) ?? Date(), isNotCurrentMonth: true))
        }
        
        //달력과 같은 배치의 이차원 배열로 변환하여 리턴
        var result = [[DateValue]]()
        
        days.forEach {
            if result.isEmpty || result.last?.count == 7 {
                result.append([$0])
            } else {
                result[result.count - 1].append($0)
            }
        }
        return result
    }
}


struct CardView: View {
    //@Binding var edit : Bool
    @Binding var value: DateValue
    @State var schedule: Schedule
    @ObservedObject var dateValueVM: DateValueViewModel
    @State var isReadOnly: Bool
    @Binding var edit: Bool
    @Binding var getData: Bool
    func selectedDate() {
        if isReadOnly == false {
            value.selectedToggle()
            // 클릭할 때마다 클릭 여부를 변경
            print("tap\(value.isSelected)")
        }
    }
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
                                    if edit == false {
                                    selectedDate()
                                    let dateValue = DateValue(day: value.day, date: value.date.withoutTime())
                                    value.saveDateValueToFirestore(dateValue: value)
                                    dateValueVM.removeDuplicateDay(dateValue: dateValue)
                                    } else {
                                        getData.toggle()
                                    }
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
                                )
                        } else if schedule.startDate.withoutTime() > value.date {
                            Text("\(value.day)")
                                .font(.custom("Pretendard-SemiBold", fixedSize: 18))
                                .foregroundColor(value.isSelected ? Color(UIColor.customBlue) : (value.isSecondSelected ? Color(UIColor.customRed) : Color(UIColor.customDarkGray)))
                                .padding([.leading, .bottom], 10)
                        }
                        else {
                            Text("\(value.day)")
                                .font(.custom("Pretendard-SemiBold", fixedSize: 18))
                                .foregroundColor((value.date.weekday == 1 || value.date.weekday == 2) ? (value.isSelected ? Color(UIColor.customBlue) : (value.isSecondSelected ? Color(UIColor.customRed) : Color(UIColor.customDarkGray))) : (value.isSelected ? Color(UIColor.customDarkGray) : (value.isSecondSelected ? Color(UIColor.customRed) : Color(UIColor.customBlue))))
                                .padding([.leading, .bottom], 10)
                                .onTapGesture {
                                    if edit == false  {
                                    selectedDate()
                                    let dateValue = DateValue(day: value.day, date: value.date.withoutTime())
                                    value.saveDateValueToFirestore(dateValue: value)
                                    dateValueVM.removeDuplicateDay(dateValue: dateValue)
                                    } else {
                                        getData.toggle()
                                    }
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

#Preview {
    CalendarView()
    
}
