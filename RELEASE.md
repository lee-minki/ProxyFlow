# ProxyFlow 릴리즈 가이드

## 📦 빌드 및 패키징

### 빠른 빌드
```bash
cd "/Users/mk/worksapces/wifi proxy 변경/ProxyFlow"
./build.sh
```

### 결과물 위치
- **앱 번들**: `dist/ProxyFlow.app`
- **배포용 ZIP**: `dist/ProxyFlow-v{버전}.zip`

---

## 🚀 GitHub Releases를 통한 배포

### 1. 버전 업데이트
`ProxyFlow/AppVersion.swift` 파일에서 버전 수정:
```swift
static let patch = 3  // 버전 번호 증가
```

### 2. 빌드 및 커밋
```bash
./build.sh
git add .
git commit -m "🚀 v0.0.3 - 새 기능 추가"
git tag -a v0.0.3 -m "v0.0.3 Release"
git push origin main --tags
```

### 3. GitHub Release 생성
```bash
# GitHub CLI 사용
gh release create v0.0.3 \
  --title "ProxyFlow v0.0.3" \
  --notes "## 변경사항
- 새 기능 1
- 버그 수정" \
  dist/ProxyFlow-v0.0.3.zip
```

또는 GitHub 웹에서:
1. https://github.com/lee-minki/ProxyFlow/releases
2. "Draft a new release" 클릭
3. 태그 선택, 제목/설명 작성
4. ZIP 파일 업로드
5. "Publish release" 클릭

---

## 📱 사용자 업데이트 방법

### 수동 업데이트 (현재)
1. GitHub Releases 페이지 방문
2. 최신 버전 ZIP 다운로드
3. 기존 앱 삭제 후 새 앱 설치

### 자동 업데이트 (향후 - Sparkle Framework)
Sparkle을 통합하면 앱 내에서 자동 업데이트 확인 가능:
```bash
# Sparkle 설치
brew install sparkle
```

---

## 📋 릴리즈 체크리스트

- [ ] `AppVersion.swift` 버전 업데이트
- [ ] 기능 테스트 완료
- [ ] `./build.sh` 실행
- [ ] Git 커밋 및 태그
- [ ] GitHub Release 생성
- [ ] ZIP 파일 업로드
- [ ] README 업데이트 (필요시)
