import SwiftUI

/// 메뉴바 드롭다운 UI
struct MenuBarView: View {
    @ObservedObject var proxyService: ProxyService
    @State private var showingSettings = false
    @State private var showingLogs = false
    @State private var showingHelp = false
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
            
            // 설정/로그/도움말 섹션
            if showingSettings {
                settingsSection
                Divider().padding(.vertical, 8)
            }
            
            if showingLogs {
                logsSection
                Divider().padding(.vertical, 8)
            }
            
            if showingHelp {
                helpSection
                Divider().padding(.vertical, 8)
            }
            
            // 메뉴 버튼들
            menuButtonsSection
        }
        .padding(12)
        .frame(width: 320)
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
            
            VStack(alignment: .leading, spacing: 2) {
                Text("ProxyFlow")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("v\(AppVersion.string)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 인터넷 연결 상태 표시
            if !proxyService.isInternetConnected {
                HStack(spacing: 4) {
                    Image(systemName: "wifi.slash")
                        .font(.caption)
                        .foregroundColor(.red)
                    if let since = proxyService.disconnectedSince {
                        Text(disconnectedTimeString(since: since))
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            
            if proxyService.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
    }
    
    private func disconnectedTimeString(since: Date) -> String {
        let seconds = Int(-since.timeIntervalSinceNow)
        if seconds < 60 {
            return "\(seconds)초"
        } else {
            return "\(seconds / 60)분"
        }
    }
    
    // MARK: - Toggle Section
    
    private var toggleSection: some View {
        VStack(spacing: 8) {
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
            
            HStack {
                Circle()
                    .fill(proxyService.isProxyEnabled ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                
                Text(proxyService.isProxyEnabled ? "프록시 활성화됨" : "프록시 비활성화됨")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 인터넷 끊김 시 자동 끄기 카운트다운
                if proxyService.isProxyEnabled && !proxyService.isInternetConnected && proxyService.autoOffOnDisconnect {
                    if let since = proxyService.disconnectedSince {
                        let remaining = proxyService.autoOffTimeout - Int(-since.timeIntervalSinceNow)
                        if remaining > 0 {
                            Text("자동 끄기: \(remaining)초")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            infoRow(icon: "globe", label: "서버", value: proxyService.proxyIP.isEmpty ? "설정 필요" : proxyService.proxyIP)
            infoRow(icon: "number", label: "포트", value: proxyService.proxyPort.isEmpty ? "-" : proxyService.proxyPort)
            infoRow(icon: "wifi", label: "네트워크", value: proxyService.currentNetworkService.isEmpty ? "감지 중..." : proxyService.currentNetworkService)
            
            // 인터넷 연결 상태
            HStack(spacing: 8) {
                Image(systemName: proxyService.isInternetConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(proxyService.isInternetConnected ? .green : .red)
                    .frame(width: 16)
                
                Text("인터넷")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .leading)
                
                Text(proxyService.isInternetConnected ? "연결됨" : "끊김")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(proxyService.isInternetConnected ? .primary : .red)
                
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
                        .lineLimit(2)
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
            
            HStack {
                Text("IP:")
                    .font(.caption)
                    .frame(width: 40, alignment: .leading)
                
                TextField("192.168.1.1", text: $editingIP)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
            }
            
            HStack {
                Text("Port:")
                    .font(.caption)
                    .frame(width: 40, alignment: .leading)
                
                TextField("8080", text: $editingPort)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.red, lineWidth: (Int(editingPort) == nil && !editingPort.isEmpty) ? 1 : 0)
                    )
            }
            
            HStack {
                Spacer()
                
                Button("저장") {
                    // 입력 검증
                    guard !editingIP.isEmpty else { return }
                    guard let _ = Int(editingPort) else { return }
                    
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
                .disabled(editingIP.isEmpty || editingPort.isEmpty || Int(editingPort) == nil)
            }
            
            Divider().padding(.vertical, 6)
            
            Text("옵션")
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
            
            Toggle("앱 종료 시 프록시 끄기", isOn: Binding(
                get: { proxyService.turnOffProxyOnExit },
                set: { proxyService.turnOffProxyOnExit = $0 }
            ))
            .font(.caption)
            .toggleStyle(.checkbox)
            
            Toggle("인터넷 끊김 시 \(proxyService.autoOffTimeout)초 후 자동 끄기", isOn: Binding(
                get: { proxyService.autoOffOnDisconnect },
                set: { proxyService.autoOffOnDisconnect = $0 }
            ))
            .font(.caption)
            .toggleStyle(.checkbox)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    // MARK: - Logs Section
    
    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("로그")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("지우기") {
                    proxyService.logMessages.removeAll()
                }
                .font(.caption2)
                .buttonStyle(.plain)
                .foregroundColor(.blue)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(proxyService.logMessages.reversed(), id: \.self) { log in
                        Text(log)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 100)
            .background(Color.black.opacity(0.05))
            .cornerRadius(4)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    // MARK: - Help Section
    
    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("💡 도움말")
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 6) {
                helpItem(
                    icon: "questionmark.circle",
                    title: "프록시란?",
                    description: "프록시 서버를 통해 인터넷에 연결하는 방식입니다. 회사나 특정 네트워크에서 필요할 수 있습니다."
                )
                
                helpItem(
                    icon: "wifi.exclamationmark",
                    title: "Wi-Fi 변경 시 인터넷 안됨",
                    description: "다른 Wi-Fi로 이동하면 프록시 설정이 맞지 않아 인터넷이 안될 수 있습니다. 프록시를 끄거나 설정을 변경하세요."
                )
                
                helpItem(
                    icon: "clock.arrow.circlepath",
                    title: "자동 끄기 기능",
                    description: "인터넷이 2분 이상 끊기면 프록시가 자동으로 꺼집니다. 설정에서 비활성화할 수 있습니다."
                )
                
                helpItem(
                    icon: "power",
                    title: "앱 종료 시",
                    description: "앱 종료 시 프록시가 자동으로 꺼져 인터넷 연결 문제를 방지합니다."
                )
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.05))
        )
    }
    
    private func helpItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Menu Buttons Section
    
    private var menuButtonsSection: some View {
        VStack(spacing: 2) {
            menuButton(icon: "gearshape", title: showingSettings ? "설정 닫기" : "설정") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingSettings.toggle()
                    showingLogs = false
                    showingHelp = false
                    if showingSettings {
                        editingIP = proxyService.proxyIP
                        editingPort = proxyService.proxyPort
                    }
                }
            }
            
            menuButton(icon: "doc.text", title: showingLogs ? "로그 닫기" : "로그 보기") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingLogs.toggle()
                    showingSettings = false
                    showingHelp = false
                }
            }
            
            menuButton(icon: "questionmark.circle", title: showingHelp ? "도움말 닫기" : "도움말") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingHelp.toggle()
                    showingSettings = false
                    showingLogs = false
                }
            }
            
            menuButton(icon: "arrow.clockwise", title: "상태 새로고침") {
                Task {
                    await proxyService.refreshProxyStatus()
                }
            }
            
            Divider().padding(.vertical, 4)
            
            menuButton(icon: "heart.fill", title: "개발자 후원 ($1)", iconColor: .pink) {
                if let url = URL(string: "https://buymeacoffee.com") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            Divider().padding(.vertical, 4)
            
            menuButton(icon: "power", title: "종료", iconColor: .red) {
                if proxyService.turnOffProxyOnExit {
                    proxyService.turnOffProxySync()
                }
                NSApplication.shared.terminate(nil)
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
                .fill(Color.gray.opacity(0.001))
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
        .frame(width: 320)
}
