import SwiftUI

/// ProxyFlow - macOS 메뉴바 프록시 토글 앱
@main
struct ProxyFlowApp: App {
    @StateObject private var proxyService = ProxyService()
    
    var body: some Scene {
        // 메뉴바 앱 (메인 윈도우 없음)
        MenuBarExtra {
            MenuBarView(proxyService: proxyService)
        } label: {
            menuBarIcon
        }
        .menuBarExtraStyle(.window)
    }
    
    /// 메뉴바 아이콘 (프록시 상태에 따라 변경)
    private var menuBarIcon: some View {
        Image(systemName: proxyService.isProxyEnabled 
              ? "network.badge.shield.half.filled" 
              : "network")
            .symbolRenderingMode(.hierarchical)
            .foregroundColor(proxyService.isProxyEnabled ? .blue : .primary)
    }
    
    init() {
        // 앱 종료 시 프록시 끄기 등록 (동기적으로 처리)
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            if UserDefaults.standard.bool(forKey: "ProxyFlow.turnOffOnExit") {
                turnOffProxyOnTerminate()
            }
        }
    }
}

/// 앱 종료 시 프록시 끄기 (동기적)
private func turnOffProxyOnTerminate() {
    let service = getActiveNetworkService()
    guard !service.isEmpty else { return }
    
    // HTTP 프록시 끄기
    let process1 = Process()
    process1.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
    process1.arguments = ["-setwebproxystate", service, "off"]
    try? process1.run()
    process1.waitUntilExit()
    
    // HTTPS 프록시 끄기
    let process2 = Process()
    process2.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
    process2.arguments = ["-setsecurewebproxystate", service, "off"]
    try? process2.run()
    process2.waitUntilExit()
}

/// 활성 네트워크 서비스 가져오기 (동기)
private func getActiveNetworkService() -> String {
    let process = Process()
    let pipe = Pipe()
    
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
    process.arguments = ["-listallnetworkservices"]
    process.standardOutput = pipe
    
    do {
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        let lines = output.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("*") && !$0.contains("asterisk") }
        
        // 우선순위: Wi-Fi > Ethernet
        let priorityServices = ["Wi-Fi", "Ethernet", "USB 10/100/1000 LAN"]
        
        for priority in priorityServices {
            if lines.contains(priority) {
                return priority
            }
        }
        
        return lines.first ?? ""
    } catch {
        return ""
    }
}
