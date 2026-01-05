# ProxyFlow

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13.0+-blue?style=for-the-badge&logo=apple" alt="macOS 13.0+">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange?style=for-the-badge&logo=swift" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="MIT License">
</p>

<p align="center">
  <b>macOS 메뉴바에서 시스템 프록시를 한 번의 클릭으로 토글하는 경량 앱</b>
</p>

---

## ⭐ 앱 다운로드 (Get the App)

### Option 1: 바로 사용하기 (추천)
**[📦 Gumroad에서 다운로드 ($1)](https://gumroad.com/l/YOUR_GUMROAD_LINK_HERE)**
- ✅ 미리 빌드된 설치 파일 (.dmg)
- ✅ 설치만 하면 즉시 사용 가능
- ✅ 개발자 후원 및 지속적인 업데이트 지원!

### Option 2: 소스에서 직접 빌드 (무료)
```bash
git clone https://github.com/lee-minki/ProxyFlow.git
cd ProxyFlow
# Xcode 및 Swift 개발 환경 필요
swift build -c release
```

## 💡 왜 $1인가요?
직접 빌드하려면 다음 과정이 필요합니다:
- 터미널 및 git 사용법 숙지
- Xcode Command Line Tools 설치
- 직접 빌드 및 권한 설정
- 20분 이상의 시간 소요

**커피 한 잔 값으로 시간을 아끼고 완성된 앱을 바로 사용하세요! ☕**

---

## ✨ 주요 기능

- 🔄 **원클릭 프록시 토글** - HTTP/HTTPS 프록시 동시 제어
- 📡 **인터넷 연결 모니터링** - 연결 끊김 시 자동 프록시 끄기 (2분 타임아웃)
- 🛡️ **Fail-Safe** - 앱 종료 시 프록시 자동 비활성화
- 💾 **설정 저장** - IP, Port 정보 영구 저장
- 📋 **로그 보기** - 디버깅을 위한 로그 확인

## 📸 미리보기

```
┌─────────────────────────────┐
│  🛡️ ProxyFlow  v0.0.2       │
│─────────────────────────────│
│  [ ON ━━━━━━━━○ OFF ]       │
│  ● 프록시 활성화됨           │
│─────────────────────────────│
│  📍 서버: 192.168.49.1      │
│  🔌 포트: 8228              │
│  📡 네트워크: Wi-Fi          │
│  ✅ 인터넷: 연결됨           │
└─────────────────────────────┘
```

## 🚀 설치 방법

1. 위 링크에서 DMG 파일 다운로드 또는 직접 빌드
2. DMG 파일 열기
3. ProxyFlow.app을 Applications 폴더로 드래그
4. 앱 실행 → 메뉴바에서 네트워크 아이콘 확인!

## 📋 요구사항

- macOS 13.0 (Ventura) 이상

## ⚠️ 알림

이 앱은 시스템 `networksetup` 명령어를 사용합니다.
- App Store 배포가 불가능하여 직접 배포합니다.
- 첫 실행 시 "확인되지 않은 개발자" 경고가 나올 수 있습니다.
  - 시스템 환경설정 → 보안 및 개인정보 → "확인 없이 열기" 클릭

## 💡 도움말

- **Wi-Fi 변경 시 인터넷 안됨?** → 프록시 설정이 맞지 않을 수 있습니다. 프록시를 끄세요.
- **자동 끄기 기능** → 인터넷이 2분 이상 끊기면 프록시가 자동으로 꺼집니다.

## ❤️ 후원

이 앱이 도움이 되셨다면 응원 부탁드려요!

<a href="https://buymeacoffee.com" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="50">
</a>

## 📄 라이선스
 
MIT License
