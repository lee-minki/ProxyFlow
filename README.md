# ProxyFlow

macOS 메뉴바에서 시스템 프록시를 한 번의 클릭으로 토글하는 경량 앱

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ 주요 기능

- 🔄 **원클릭 프록시 토글** - HTTP/HTTPS 프록시 동시 제어
- 📡 **SSID별 프로필 저장** - Wi-Fi 네트워크별 다른 프록시 설정 자동 적용
- 🛡️ **Fail-Safe** - 앱 종료 시 프록시 자동 비활성화
- 💾 **설정 저장** - IP, Port 정보 영구 저장

## 📸 스크린샷

```
┌─────────────────────────────┐
│  🛡️ ProxyFlow               │
│─────────────────────────────│
│  [ ON ━━━━━━━━○ OFF ]       │
│  ● 프록시 활성화됨           │
│─────────────────────────────│
│  📍 서버: 192.168.49.1      │
│  🔌 포트: 8228              │
│  📡 네트워크: Wi-Fi          │
│  📶 SSID: MyNetwork ✅       │
└─────────────────────────────┘
```

## 🚀 설치 방법

### 소스에서 빌드

```bash
git clone https://github.com/YOUR_USERNAME/ProxyFlow.git
cd ProxyFlow
swift build -c release
```

### 실행

```bash
swift run ProxyFlow
```

또는 빌드된 실행 파일 사용:
```bash
.build/release/ProxyFlow
```

## 📋 요구사항

- macOS 13.0 (Ventura) 이상
- Swift 5.9 이상

## 🔧 사용된 기술

- **Swift** - 프로그래밍 언어
- **SwiftUI** - UI 프레임워크
- **MenuBarExtra** - macOS 메뉴바 API
- **CoreWLAN** - Wi-Fi SSID 감지
- **networksetup** - 시스템 프록시 제어

## ⚠️ 알림

이 앱은 `networksetup` 명령어를 사용하므로 App Store 배포가 불가능합니다.
직접 빌드하여 사용하거나 Releases에서 다운로드하세요.

## 📄 라이선스

MIT License

## ❤️ 후원

이 앱이 도움이 되셨다면 [Buy Me a Coffee](https://buymeacoffee.com)에서 응원해주세요!
