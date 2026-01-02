import SwiftUI

/// 메뉴바 드롭다운 UI
struct MenuBarView: View {
    @ObservedObject var proxyService: ProxyService
    @State private var showingSettings = false
    @State private var editingIP: String = ""
    @State private var editingPort: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            headerSection
            
            Divider()
                .padding(.vertical, 8)
            
            // 메인 토글 스위치
            toggleSection
            
            Divider()
                .padding(.vertical, 8)
            
            // 현재 설정 정보
            infoSection
            
            Divider()
                .padding(.vertical, 8)
            
            // 설정 입력 섹션
            if showingSettings {
                settingsSection
                
                Divider()
                    .padding(.vertical, 8)
            }
            
            // 메뉴 버튼들
            menuButtonsSection
        }
        .padding(12)
        .frame(width: 280)
        .onAppear {
            editingIP = proxyService.proxyIP
            editingPort = proxyService.proxyPort
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Image(systemName: proxyService.isProxyEnabled ? "network.badge.shield.half.filled" : "network")
                .font(.title2)
                .foregroundColor(proxyService.isProxyEnabled ? .blue : .secondary)
                .animation(.easeInOut(duration: 0.3), value: proxyService.isProxyEnabled)
            
            Text("ProxyFlow")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            if proxyService.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
    }
    
    // MARK: - Toggle Section
    
    private var toggleSection: some View {
        VStack(spacing: 8) {
            // 큰 토글 스위치
            HStack {
                Text("프록시")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { proxyService.isProxyEnabled },
                    set: { _ in
                        Task {
                            await proxyService.toggleProxy()
                        }
                    }
                ))
                .toggleStyle(.switch)
                .disabled(proxyService.isLoading)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(proxyService.isProxyEnabled ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            )
            
            // 상태 텍스트
            HStack {
                Circle()
                    .fill(proxyService.isProxyEnabled ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                
                Text(proxyService.isProxyEnabled ? "프록시 활성화됨" : "프록시 비활성화됨")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            infoRow(icon: "globe", label: "서버", value: proxyService.proxyIP.isEmpty ? "설정 필요" : proxyService.proxyIP)
            infoRow(icon: "number", label: "포트", value: proxyService.proxyPort.isEmpty ? "-" : proxyService.proxyPort)
            infoRow(icon: "wifi", label: "네트워크", value: proxyService.currentNetworkService.isEmpty ? "감지 중..." : proxyService.currentNetworkService)
            
            // SSID 정보 표시
            HStack(spacing: 8) {
                Image(systemName: "wifi.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                Text("SSID")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .leading)
                
                Text(proxyService.currentSSID.isEmpty ? "감지 중..." : proxyService.currentSSID)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                // 프로필 자동 적용 표시
                if proxyService.profileAutoApplied {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
            
            if let error = proxyService.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.top, 4)
            }
        }
    }
    
    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Spacer()
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("프록시 설정")
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
            
            // IP 입력
            HStack {
                Text("IP:")
                    .font(.caption)
                    .frame(width: 40, alignment: .leading)
                
                TextField("192.168.1.1", text: $editingIP)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
            }
            
            // 포트 입력
            HStack {
                Text("Port:")
                    .font(.caption)
                    .frame(width: 40, alignment: .leading)
                
                TextField("8080", text: $editingPort)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
            }
            
            // 저장 버튼
            HStack {
                Spacer()
                
                Button("저장") {
                    proxyService.proxyIP = editingIP
                    proxyService.proxyPort = editingPort
                    
                    Task {
                        await proxyService.updateProxySettings()
                    }
                    
                    withAnimation {
                        showingSettings = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(editingIP.isEmpty || editingPort.isEmpty)
            }
            
            Divider()
                .padding(.vertical, 6)
            
            Text("옵션")
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
            
            // 앱 종료 시 프록시 끄기 옵션
            Toggle("앱 종료 시 프록시 끄기", isOn: Binding(
                get: { proxyService.turnOffProxyOnExit },
                set: { proxyService.turnOffProxyOnExit = $0 }
            ))
            .font(.caption)
            .toggleStyle(.checkbox)
            
            // SSID 프로필 자동 적용 옵션
            Toggle("Wi-Fi별 설정 자동 적용", isOn: Binding(
                get: { proxyService.autoApplySSIDProfile },
                set: { proxyService.autoApplySSIDProfile = $0 }
            ))
            .font(.caption)
            .toggleStyle(.checkbox)
            
            // 저장된 프로필 개수 표시
            if !proxyService.profileStore.profiles.isEmpty {
                HStack {
                    Image(systemName: "list.bullet")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("저장된 Wi-Fi: \(proxyService.profileStore.profiles.count)개")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    // MARK: - Menu Buttons Section
    
    private var menuButtonsSection: some View {
        VStack(spacing: 2) {
            // 설정 버튼
            menuButton(icon: "gearshape", title: showingSettings ? "설정 닫기" : "설정") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingSettings.toggle()
                    if showingSettings {
                        editingIP = proxyService.proxyIP
                        editingPort = proxyService.proxyPort
                    }
                }
            }
            
            // 새로고침 버튼
            menuButton(icon: "arrow.clockwise", title: "상태 새로고침") {
                Task {
                    await proxyService.refreshProxyStatus()
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // 후원 버튼
            menuButton(icon: "heart.fill", title: "개발자 후원 ($1)", iconColor: .pink) {
                if let url = URL(string: "https://buymeacoffee.com") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // 종료 버튼
            menuButton(icon: "power", title: "종료", iconColor: .red) {
                Task {
                    if proxyService.turnOffProxyOnExit {
                        await proxyService.turnOffProxy()
                    }
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }
    
    private func menuButton(icon: String, title: String, iconColor: Color = .primary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(iconColor)
                    .frame(width: 16)
                
                Text(title)
                    .font(.subheadline)
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.001)) // 클릭 영역 확보
        )
        .onHover { isHovered in
            if isHovered {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

#Preview {
    MenuBarView(proxyService: ProxyService())
        .frame(width: 280)
}
