# 🎤 Speech Coach

말하기 영상을 분석해 **발화 흐름 · 전달력 · 말하기 습관을 개선**할 수 있도록 돕는  
iOS 기반 스피치 코칭 앱입니다.

> 단순 분석이 아닌,  
> **사용자가 스스로 말하기를 개선할 수 있도록 돕는 구조**에 집중했습니다.

---

## 📱 App Preview

| Analysis Overview | Analysis Detail | Practice Note | Coaching |
|------------------|----------------|----------------|-----------|
| ![](img/analysis-overview.png) | ![](img/analysis-detail.png) | ![](img/note.png) | ![](img/coaching.png) |


---

## ✨ Key Features

### 🎙 Speech Analysis
- 발화 속도 및 침묵 구간 기반 분석
- 말하기 흐름을 기준으로 한 유형 요약
- 분석 신뢰도가 낮을 경우 안내 메시지 제공

### 🧠 Coaching & Feedback
- 하이라이트 기반 코칭 카드 제공
- 코칭 메모 작성 및 저장
- 말하기 유형별 개선 포인트 제시

### 📊 Result Management
- 분석 결과 저장 및 재확인
- 하이라이트 기반 재생
- 최근 기록 중심의 결과 화면 구성

---

## 🛠 Tech Stack

- **Language**: Swift  
- **UI**: SwiftUI  
- **Architecture**: MVVM  
- **Persistence**: Core Data  
- **Media**: AVFoundation  
- **Monitoring**: Firebase Crashlytics  

---

## 🧩 Architecture Overview

- SpeechRecord / Metrics / Highlight 구조 분리
- recordID 기반 ViewModel 설계
- PlayerController를 통한 AVPlayer 제어 일원화
- 분석 → 피드백 → 재생 흐름을 단방향 구조로 설계

---

## 🤔 Technical Challenges

### 1. 분석 결과와 영상 재생 동기화
- 문제: 분석 결과와 실제 영상 재생 위치 불일치
- 해결: AVPlayer 제어 로직을 PlayerController로 통합

### 2. 분석 신뢰도에 따른 UX 처리
- 문제: STT 정확도가 낮을 경우 잘못된 피드백 제공
- 해결: 신뢰도 기준 분기 및 안내 UI 추가

### 3. 확장 가능한 구조 설계
- MVP 단계에서도 이후 기능 확장을 고려한 구조 설계
- Result / Highlight / Coaching 영역 분리

---

## 📦 Release

### v1.0.0 — Initial Release
- Speech analysis & feedback flow
- Highlight-based coaching
- Improved playback stability
- UX refinement & bug fixes

👉 [Release Notes 보기](https://github.com/puuurm/Speech-Coach/releases)

---

## 🚀 Roadmap

- 분석 정확도 고도화
- 코칭 알고리즘 확장
- 사용자 피드백 기반 UX 개선
- 시각화 리포트 추가

---

## 🧑‍💻 Author

- iOS Developer  
- 개인 프로젝트 / App Store 배포 경험  
- 관심사: UX 중심 앱 설계, 사용자 행동 분석
