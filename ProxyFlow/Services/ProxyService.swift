import Foundation
import Combine
import Network

/// ProxyService: 시스템 프록시 설정을 관리하는 핵심 서비스
/// networksetup 셸 명령어를 사용하여 HTTP/HTTPS 프록시를 제어합니다.
@MainActor
class ProxyService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 현재 프록시 활성화 상태
    @Published var isProxyEnabled: Bool = false
    
    /// 현재 감지된 네트워크 서비스 이름 (예: "Wi-Fi")
    @Published var currentNetworkService: String = ""
    
    /// 프록시 서버 IP 주소
    @Published var proxyIP: String = "" {
        didSet { saveSettings() }
    }
    
    /// 프록시 서버 포트
    @Published var proxyPort: String = "" {
        didSet { saveSettings() }
    }
    
    /// 로딩 상태 (UI에서 스피너 표시용)
    @Published var isLoading: Bool = false
    
    /// 에러 메시지
    @Published var errorMessage: String?
    
    /// 마지막 상태 업데이트 시간
    @Published var lastUpdated: Date?
    
    /// 로그 메시지 (디버깅용)
    @Published var logMessages: [String] = []
    
    /// 인터넷 연결 상태
    @Published var isInternetConnected: Bool = true
    
    /// 인터넷 끊김 시작 시간
    @Published var disconnectedSince: Date?
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let proxyIPKey = "ProxyFlow.proxyIP"
    private let proxyPortKey = "ProxyFlow.proxyPort"
    private let turnOffOnExitKey = "ProxyFlow.turnOffOnExit"
    private let autoOffOnDisconnectKey = "ProxyFlow.autoOffOnDisconnect"
    private let autoOffTimeoutKey = "ProxyFlow.autoOffTimeout"
    
    private var networkMonitor: NWPathMonitor?
    private var monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var disconnectTimer: Timer?
    
    /// 앱 종료 시 프록시 끄기 옵션
    var turnOffProxyOnExit: Bool {
        get { userDefaults.bool(forKey: turnOffOnExitKey) }
        set { userDefaults.set(newValue, forKey: turnOffOnExitKey) }
    }
    
    /// 인터넷 끊김 시 프록시 자동 끄기 옵션
    var autoOffOnDisconnect: Bool {
        get { 
            if userDefaults.object(forKey: autoOffOnDisconnectKey) == nil {
                return true // 기본값: 활성화
            }
            return userDefaults.bool(forKey: autoOffOnDisconnectKey) 
        }
        set { userDefaults.set(newValue, forKey: autoOffOnDisconnectKey) }
    }
    
    /// 자동 끄기 타임아웃 (초) - 기본 120초 (2분)
    var autoOffTimeout: Int {
        get { 
            let value = userDefaults.integer(forKey: autoOffTimeoutKey)
            return value > 0 ? value : 120
        }
        set { userDefaults.set(newValue, forKey: autoOffTimeoutKey) }
    }
    
    // MARK: - Initialization
    
    init() {
        log("ProxyService 초기화 시작")
        loadSettings()
        startNetworkMonitoring()
        
        // 초기 상태 확인
        Task {
            await detectNetworkService()
            await refreshProxyStatus()
            log("ProxyService 초기화 완료")
        }
    }
    
    deinit {
        networkMonitor?.cancel()
        disconnectTimer?.invalidate()
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handleNetworkChange(path: path)
            }
        }
        networkMonitor?.start(queue: monitorQueue)
        log("네트워크 모니터링 시작")
    }
    
    private func handleNetworkChange(path: NWPath) {
        let wasConnected = isInternetConnected
        isInternetConnected = path.status == .satisfied
        
        log("네트워크 상태 변경: \(isInternetConnected ? "연결됨" : "끊김")")
        
        if !isInternetConnected && wasConnected {
            // 인터넷이 끊김
            disconnectedSince = Date()
            startDisconnectTimer()
        } else if isInternetConnected {
            // 인터넷 복구됨
            disconnectedSince = nil
            stopDisconnectTimer()
        }
    }
    
    private func startDisconnectTimer() {
        guard autoOffOnDisconnect, isProxyEnabled else { return }
        
        stopDisconnectTimer()
        
        log("인터넷 끊김 감지 - \(autoOffTimeout)초 후 프록시 자동 끄기 예정")
        
        disconnectTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(autoOffTimeout), repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                // 여전히 끊겨있고 프록시가 켜져있다면 끄기
                if !self.isInternetConnected && self.isProxyEnabled {
                    self.log("⚠️ 인터넷 \(self.autoOffTimeout)초 이상 끊김 - 프록시 자동 끄기")
                    self.errorMessage = "인터넷 끊김으로 프록시가 자동으로 꺼졌습니다"
                    await self.toggleProxy()
                }
            }
        }
    }
    
    private func stopDisconnectTimer() {
        disconnectTimer?.invalidate()
        disconnectTimer = nil
    }
    
    // MARK: - Logging
    
    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logEntry = "[\(timestamp)] \(message)"
        logMessages.append(logEntry)
        
        // 최대 50개 로그만 유지
        if logMessages.count > 50 {
            logMessages.removeFirst()
        }
        
        // 콘솔에도 출력
        print("[ProxyFlow] \(message)")
    }
    
    // MARK: - Settings Persistence
    
    private func loadSettings() {
        proxyIP = userDefaults.string(forKey: proxyIPKey) ?? ""
        proxyPort = userDefaults.string(forKey: proxyPortKey) ?? ""
        
        // 기본값: 앱 종료 시 프록시 끄기 활성화
        if userDefaults.object(forKey: turnOffOnExitKey) == nil {
            userDefaults.set(true, forKey: turnOffOnExitKey)
        }
        log("설정 로드 완료 - IP: \(proxyIP), Port: \(proxyPort)")
    }
    
    private func saveSettings() {
        userDefaults.set(proxyIP, forKey: proxyIPKey)
        userDefaults.set(proxyPort, forKey: proxyPortKey)
    }
    
    // MARK: - Network Service Detection
    
    /// 활성 네트워크 서비스 감지 (Wi-Fi 또는 Ethernet 우선)
    func detectNetworkService() async {
        log("네트워크 서비스 감지 시작")
        
        let output = await runCommand("networksetup", arguments: ["-listallnetworkservices"])
        
        let lines = output.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("*") && !$0.contains("asterisk") }
        
        // 우선순위: Wi-Fi > Ethernet > 첫 번째 서비스
        let priorityServices = ["Wi-Fi", "Ethernet", "USB 10/100/1000 LAN", "USB 10/100 LAN", "Thunderbolt Ethernet"]
        
        for priority in priorityServices {
            if lines.contains(priority) {
                currentNetworkService = priority
                log("네트워크 서비스 감지됨: \(priority)")
                return
            }
        }
        
        // 우선순위 서비스가 없으면 첫 번째 유효한 서비스 사용
        if let firstService = lines.first(where: { !$0.contains("Bridge") && !$0.contains("VPN") }) {
            currentNetworkService = firstService
            log("대체 네트워크 서비스 사용: \(firstService)")
        } else if let anyService = lines.first {
            currentNetworkService = anyService
            log("첫 번째 네트워크 서비스 사용: \(anyService)")
        } else {
            log("네트워크 서비스를 찾을 수 없음")
        }
    }
    
    // MARK: - Proxy Status
    
    /// 현재 프록시 상태 새로고침
    func refreshProxyStatus() async {
        log("프록시 상태 새로고침 시작")
        
        if currentNetworkService.isEmpty {
            await detectNetworkService()
        }
        
        guard !currentNetworkService.isEmpty else {
            errorMessage = "네트워크 서비스를 찾을 수 없습니다."
            log("오류: 네트워크 서비스 없음")
            return
        }
        
        let output = await runCommand("networksetup", arguments: ["-getwebproxy", currentNetworkService])
        
        // 출력 파싱
        let lines = output.components(separatedBy: "\n")
        var enabled = false
        var server = ""
        var port = ""
        
        for line in lines {
            let parts = line.components(separatedBy: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 2 {
                switch parts[0].lowercased() {
                case "enabled":
                    enabled = parts[1].lowercased() == "yes"
                case "server":
                    server = parts[1]
                case "port":
                    port = parts[1]
                default:
                    break
                }
            }
        }
        
        isProxyEnabled = enabled
        log("프록시 상태: \(enabled ? "활성화" : "비활성화"), 서버: \(server):\(port)")
        
        // 저장된 설정이 없으면 현재 시스템 설정 사용
        if proxyIP.isEmpty && !server.isEmpty {
            proxyIP = server
        }
        if proxyPort.isEmpty && !port.isEmpty && port != "0" {
            proxyPort = port
        }
        
        lastUpdated = Date()
        errorMessage = nil
    }
    
    // MARK: - Proxy Toggle
    
    /// 프록시 토글 (켜기/끄기)
    func toggleProxy() async {
        log("프록시 토글 시작 (현재: \(isProxyEnabled ? "ON" : "OFF"))")
        isLoading = true
        errorMessage = nil
        
        defer { 
            isLoading = false 
            log("프록시 토글 완료")
        }
        
        guard !currentNetworkService.isEmpty else {
            errorMessage = "네트워크 서비스가 선택되지 않았습니다."
            log("오류: 네트워크 서비스 없음")
            return
        }
        
        let newState = !isProxyEnabled
        let stateString = newState ? "on" : "off"
        
        // 프록시를 켤 때는 먼저 서버/포트 설정
        if newState {
            guard !proxyIP.isEmpty, !proxyPort.isEmpty else {
                errorMessage = "프록시 IP와 포트를 입력해주세요."
                log("오류: IP 또는 Port 없음")
                return
            }
            
            log("프록시 설정 중: \(proxyIP):\(proxyPort)")
            
            // HTTP 프록시 설정
            let httpResult = await runCommand("networksetup", arguments: [
                "-setwebproxy", currentNetworkService, proxyIP, proxyPort
            ])
            
            // HTTPS 프록시 설정
            let httpsResult = await runCommand("networksetup", arguments: [
                "-setsecurewebproxy", currentNetworkService, proxyIP, proxyPort
            ])
            
            if httpResult.contains("Error") || httpsResult.contains("Error") {
                errorMessage = "프록시 설정 실패: 권한을 확인해주세요."
                log("오류: 프록시 설정 실패 - HTTP: \(httpResult), HTTPS: \(httpsResult)")
                return
            }
        }
        
        log("프록시 상태 변경: \(stateString)")
        
        // HTTP 프록시 상태 변경
        let httpStateResult = await runCommand("networksetup", arguments: [
            "-setwebproxystate", currentNetworkService, stateString
        ])
        
        // HTTPS 프록시 상태 변경
        let httpsStateResult = await runCommand("networksetup", arguments: [
            "-setsecurewebproxystate", currentNetworkService, stateString
        ])
        
        if httpStateResult.contains("Error") || httpsStateResult.contains("Error") {
            errorMessage = "프록시 상태 변경 실패"
            log("오류: 상태 변경 실패")
            return
        }
        
        // 상태 갱신
        await refreshProxyStatus()
    }
    
    /// 프록시 끄기 (앱 종료 시 사용) - 동기 버전
    func turnOffProxySync() {
        guard !currentNetworkService.isEmpty else { return }
        
        log("프록시 끄기 (동기)")
        
        let process1 = Process()
        process1.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        process1.arguments = ["-setwebproxystate", currentNetworkService, "off"]
        try? process1.run()
        process1.waitUntilExit()
        
        let process2 = Process()
        process2.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        process2.arguments = ["-setsecurewebproxystate", currentNetworkService, "off"]
        try? process2.run()
        process2.waitUntilExit()
    }
    
    /// 프록시 끄기 (앱 종료 시 사용)
    func turnOffProxy() async {
        guard !currentNetworkService.isEmpty, isProxyEnabled else { return }
        
        log("프록시 끄기 (비동기)")
        
        _ = await runCommand("networksetup", arguments: [
            "-setwebproxystate", currentNetworkService, "off"
        ])
        _ = await runCommand("networksetup", arguments: [
            "-setsecurewebproxystate", currentNetworkService, "off"
        ])
    }
    
    /// 프록시 설정 업데이트 (IP, Port 변경 시)
    func updateProxySettings() async {
        guard !proxyIP.isEmpty, !proxyPort.isEmpty, !currentNetworkService.isEmpty else { return }
        
        log("프록시 설정 업데이트: \(proxyIP):\(proxyPort)")
        isLoading = true
        defer { isLoading = false }
        
        // HTTP 프록시 설정
        _ = await runCommand("networksetup", arguments: [
            "-setwebproxy", currentNetworkService, proxyIP, proxyPort
        ])
        
        // HTTPS 프록시 설정
        _ = await runCommand("networksetup", arguments: [
            "-setsecurewebproxy", currentNetworkService, proxyIP, proxyPort
        ])
        
        await refreshProxyStatus()
    }
    
    // MARK: - Shell Command Execution
    
    /// 셸 명령어 비동기 실행 (타임아웃 5초)
    private func runCommand(_ command: String, arguments: [String]) async -> String {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let pipe = Pipe()
                
                process.executableURL = URL(fileURLWithPath: "/usr/sbin/\(command)")
                process.arguments = arguments
                process.standardOutput = pipe
                process.standardError = pipe
                
                do {
                    try process.run()
                    
                    // 타임아웃 5초
                    DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                        if process.isRunning {
                            process.terminate()
                        }
                    }
                    
                    process.waitUntilExit()
                    
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    continuation.resume(returning: output)
                } catch {
                    continuation.resume(returning: "Error: \(error.localizedDescription)")
                }
            }
        }
    }
}
