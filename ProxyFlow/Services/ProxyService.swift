import Foundation
import Combine
import CoreWLAN

/// ProxyService: 시스템 프록시 설정을 관리하는 핵심 서비스
/// networksetup 셸 명령어를 사용하여 HTTP/HTTPS 프록시를 제어합니다.
@MainActor
class ProxyService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 현재 프록시 활성화 상태
    @Published var isProxyEnabled: Bool = false
    
    /// 현재 감지된 네트워크 서비스 이름 (예: "Wi-Fi")
    @Published var currentNetworkService: String = ""
    
    /// 현재 연결된 Wi-Fi SSID
    @Published var currentSSID: String = ""
    
    /// 프록시 서버 IP 주소
    @Published var proxyIP: String = "" {
        didSet { 
            saveSettings()
            // 현재 SSID가 있으면 프로필도 자동 저장
            saveCurrentProfileIfNeeded()
        }
    }
    
    /// 프록시 서버 포트
    @Published var proxyPort: String = "" {
        didSet { 
            saveSettings()
            saveCurrentProfileIfNeeded()
        }
    }
    
    /// 로딩 상태 (UI에서 스피너 표시용)
    @Published var isLoading: Bool = false
    
    /// 에러 메시지
    @Published var errorMessage: String?
    
    /// 마지막 상태 업데이트 시간
    @Published var lastUpdated: Date?
    
    /// SSID 프로필이 자동 적용되었는지 여부
    @Published var profileAutoApplied: Bool = false
    
    // MARK: - Profile Store
    
    /// SSID별 프록시 프로필 저장소
    let profileStore = ProxyProfileStore()
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let proxyIPKey = "ProxyFlow.proxyIP"
    private let proxyPortKey = "ProxyFlow.proxyPort"
    private let turnOffOnExitKey = "ProxyFlow.turnOffOnExit"
    private let autoApplyProfileKey = "ProxyFlow.autoApplyProfile"
    
    /// 앱 종료 시 프록시 끄기 옵션
    var turnOffProxyOnExit: Bool {
        get { userDefaults.bool(forKey: turnOffOnExitKey) }
        set { userDefaults.set(newValue, forKey: turnOffOnExitKey) }
    }
    
    /// SSID 프로필 자동 적용 옵션
    var autoApplySSIDProfile: Bool {
        get { 
            // 기본값: true
            if userDefaults.object(forKey: autoApplyProfileKey) == nil {
                return true
            }
            return userDefaults.bool(forKey: autoApplyProfileKey) 
        }
        set { userDefaults.set(newValue, forKey: autoApplyProfileKey) }
    }
    
    // MARK: - Initialization
    
    init() {
        loadSettings()
        
        // 초기 상태 확인
        Task {
            await detectNetworkService()
            await detectCurrentSSID()
            await refreshProxyStatus()
            
            // SSID 프로필 자동 적용
            if autoApplySSIDProfile {
                applyProfileForCurrentSSID()
            }
        }
    }
    
    // MARK: - Settings Persistence
    
    private func loadSettings() {
        proxyIP = userDefaults.string(forKey: proxyIPKey) ?? ""
        proxyPort = userDefaults.string(forKey: proxyPortKey) ?? ""
        
        // 기본값: 앱 종료 시 프록시 끄기 활성화
        if userDefaults.object(forKey: turnOffOnExitKey) == nil {
            userDefaults.set(true, forKey: turnOffOnExitKey)
        }
    }
    
    private func saveSettings() {
        userDefaults.set(proxyIP, forKey: proxyIPKey)
        userDefaults.set(proxyPort, forKey: proxyPortKey)
    }
    
    /// 현재 SSID에 대한 프로필 저장 (IP/Port가 유효할 때만)
    private func saveCurrentProfileIfNeeded() {
        guard !currentSSID.isEmpty, 
              !proxyIP.isEmpty, 
              !proxyPort.isEmpty else { return }
        
        profileStore.saveProfile(ssid: currentSSID, ip: proxyIP, port: proxyPort)
    }
    
    // MARK: - SSID Detection
    
    /// 현재 연결된 Wi-Fi SSID 감지
    func detectCurrentSSID() async {
        // CoreWLAN을 사용하여 SSID 감지
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                var ssid = ""
                
                if let interface = CWWiFiClient.shared().interface() {
                    ssid = interface.ssid() ?? ""
                }
                
                DispatchQueue.main.async {
                    self?.currentSSID = ssid
                    continuation.resume()
                }
            }
        }
    }
    
    /// 현재 SSID에 해당하는 프로필 적용
    func applyProfileForCurrentSSID() {
        guard !currentSSID.isEmpty else { return }
        
        if let profile = profileStore.profile(for: currentSSID) {
            // 저장된 프로필이 있으면 자동 적용
            proxyIP = profile.ip
            proxyPort = profile.port
            profileAutoApplied = true
            
            // 프로필 사용 시간 업데이트
            profileStore.saveProfile(ssid: currentSSID, ip: profile.ip, port: profile.port)
        } else {
            profileAutoApplied = false
        }
    }
    
    /// 현재 설정을 SSID 프로필로 저장
    func saveCurrentAsProfile() {
        guard !currentSSID.isEmpty else {
            errorMessage = "연결된 Wi-Fi가 없습니다."
            return
        }
        guard !proxyIP.isEmpty, !proxyPort.isEmpty else {
            errorMessage = "IP와 포트를 입력해주세요."
            return
        }
        
        profileStore.saveProfile(ssid: currentSSID, ip: proxyIP, port: proxyPort)
        errorMessage = nil
    }
    
    // MARK: - Network Service Detection
    
    /// 활성 네트워크 서비스 감지 (Wi-Fi 또는 Ethernet 우선)
    func detectNetworkService() async {
        let output = await runCommand("networksetup", arguments: ["-listallnetworkservices"])
        
        let lines = output.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("*") && !$0.contains("asterisk") }
        
        // 우선순위: Wi-Fi > Ethernet > 첫 번째 서비스
        let priorityServices = ["Wi-Fi", "Ethernet", "USB 10/100/1000 LAN", "USB 10/100 LAN", "Thunderbolt Ethernet"]
        
        for priority in priorityServices {
            if lines.contains(priority) {
                currentNetworkService = priority
                return
            }
        }
        
        // 우선순위 서비스가 없으면 첫 번째 유효한 서비스 사용
        if let firstService = lines.first(where: { !$0.contains("Bridge") && !$0.contains("VPN") }) {
            currentNetworkService = firstService
        } else if let anyService = lines.first {
            currentNetworkService = anyService
        }
    }
    
    // MARK: - Proxy Status
    
    /// 현재 프록시 상태 새로고침
    func refreshProxyStatus() async {
        if currentNetworkService.isEmpty {
            await detectNetworkService()
        }
        
        guard !currentNetworkService.isEmpty else {
            errorMessage = "네트워크 서비스를 찾을 수 없습니다."
            return
        }
        
        // SSID도 함께 새로고침
        await detectCurrentSSID()
        
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
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard !currentNetworkService.isEmpty else {
            errorMessage = "네트워크 서비스가 선택되지 않았습니다."
            return
        }
        
        let newState = !isProxyEnabled
        let stateString = newState ? "on" : "off"
        
        // 프록시를 켤 때는 먼저 서버/포트 설정
        if newState {
            guard !proxyIP.isEmpty, !proxyPort.isEmpty else {
                errorMessage = "프록시 IP와 포트를 입력해주세요."
                return
            }
            
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
                return
            }
            
            // 프록시를 켤 때 현재 SSID에 프로필 저장
            saveCurrentAsProfile()
        }
        
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
            return
        }
        
        // 상태 갱신
        await refreshProxyStatus()
    }
    
    /// 프록시 끄기 (앱 종료 시 사용)
    func turnOffProxy() async {
        guard !currentNetworkService.isEmpty, isProxyEnabled else { return }
        
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
        
        // SSID 프로필로도 저장
        saveCurrentAsProfile()
        
        await refreshProxyStatus()
    }
    
    // MARK: - Shell Command Execution
    
    /// 셸 명령어 비동기 실행
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
