# PJ3T6_Sinina
# 프로젝트 명 : 시니나케이크

> “주문제작케이크 전문점 **시니나케이크**의 주문 예약 앱”
> 

# 프로젝트 소개


### 1. 회원가입과 로그인도 간편하게!

### 2. ****복잡하게 카카오톡으로 주문하던 방식을 앱에서 한 번에!****

### 3. ****주문 일정을 쉽고 빠르게 확인 가능!****

점주는 진행 중인 주문 내역을 한눈에 관리할 수 있습니다.

### 4. ****적립도 간편하게!****

번거로운 명함형태 쿠폰 대신, 항상 가지고 다니는 폰으로 적립 가능! 또한, 회원 등급에 따른 혜택도 존재합니다!

### 5. 픽업일이 다가오면 푸쉬알림으로 잊지 않게!

# 프로젝트 특징


### 1. 사용자 중심 디자인

사용자의 편의성을 최우선으로 고려한 디자인으로, 케이크 선택부터 주문까지 모든 과정을 간편하게 진행할 수 있습니다.

### 2. 푸시 알림 기능

클라우드 메시징을 통해 주문 상태 업데이트를 실시간으로 알림, 사용자가 주문 상태를 쉽게 파악할 수 있습니다.

### 3. 인스타그램 API 활용

최신 케이크 디자인을 인스타그램에서 바로 불러와, 사용자에게 다양한 디자인 선택지를 제공합니다.

### 4. 강력한 데이터 관리

Firebase Firestore를 통해 주문 데이터를 안전하게 관리하며, 실시간으로 업데이트하고 조회할 수 있습니다.

### 5. 유연한 확장성

모듈화된 기술 스택을 활용해, 비슷한 컨셉의 다른 앱에도 쉽게 적용할 수 있습니다. 이를 통해 개발 시간을 단축하고, 비용을 절약할 수 있습니다.

### 6. 다양한 로그인 옵션

Apple과 카카오를 포함한 다양한 로그인 옵션을 제공하여, 사용자가 편한 방식으로 로그인할 수 있습니다.

# 사용기술


최소기능 이외의 확장기능은 ~~Strike-through~~ 표시

### 🔥 **Firebase**

- **회원가입, 로그인 - Authentication**을 사용하여 사용자 인증 기능을 구현
- **주문 내역 -** **Firestore**를 사용하여 상품 정보, 장바구니, 주문 내역 등의 데이터를 저장하고 관리
- **케이크 디자인 시안 이미지 저장 -** **Storage**를 사용하여 상품 이미지, 리뷰 이미지 등의 미디어 파일을 업로드하고 다운로드
- **픽업, 주문완료 알림** - **Cloud Messaging**을 사용하여 푸시 알림 기능을 구현(주문, 픽업 등의 이벤트에 대해 점주와 고객에게 알림)

- 채팅 - **Realtime Database**를 사용하여 고객과 점주와의 **1:1 채팅**

### 💕Meta

- **Instagram Basic Display API - 인스타그램 매장 계정의 피드를 앱에서 볼 수 있다.**

### 🍏 Apple

- Apple 로그인

### 🍀 네이버

- 네이버 지도 API
- 네이버 간편 로그인
- ~~결제 **- 네이버페이**~~

### 💸 **Kakao**

- 카카오 간편 로그인
- ~~결제 **- 카카오페이**~~

# 기대효과

### 🍎 앱의 측면

- 사용자는 원하는 케이크를 제작하기 위한 다양한 옵션을 한눈에 확인할 수 있습니다.
- 점주용 앱을 통해 주문 내역과 일정을 한 번에 효율적으로 관리할 수 있습니다.

### 🦁 개발팀의 측면

- 팀끼리 정한 Convention을 지키며 가독성 좋은 코드를 작성합니다.
- 디자인 시안을 그대로 구현합니다.
- 기간 단위를 쪼개서 나온 결과물을 보고 다시 목표를 정하며 애자일 방식을 경험합니다.
- Firebase에서 제공하는 다양한 기능을 활용합니다.
- 출시 후에도 지속적인 앱 운영과 유지보수를 통해 업데이트를 진행합니다.
