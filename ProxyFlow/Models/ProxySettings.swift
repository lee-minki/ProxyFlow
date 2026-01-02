import Foundation

/// SSID별 프록시 프로필
struct SSIDProxyProfile: Codable, Equatable, Identifiable {
    var id: String { ssid }
    var ssid: String
    var ip: String
    var port: String
    var lastUsed: Date
    
    init(ssid: String, ip: String, port: String) {
        self.ssid = ssid
        self.ip = ip
        self.port = port
        self.lastUsed = Date()
    }
}

/// 프록시 프로필 저장소
class ProxyProfileStore: ObservableObject {
    
    @Published var profiles: [SSIDProxyProfile] = []
    
    private let userDefaults = UserDefaults.standard
    private let profilesKey = "ProxyFlow.ssidProfiles"
    
    init() {
        loadProfiles()
    }
    
    // MARK: - Profile Management
    
    /// 프로필 불러오기
    func loadProfiles() {
        guard let data = userDefaults.data(forKey: profilesKey),
              let decoded = try? JSONDecoder().decode([SSIDProxyProfile].self, from: data) else {
            profiles = []
            return
        }
        profiles = decoded.sorted { $0.lastUsed > $1.lastUsed }
    }
    
    /// 프로필 저장
    func saveProfiles() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        userDefaults.set(data, forKey: profilesKey)
    }
    
    /// SSID에 해당하는 프로필 찾기
    func profile(for ssid: String) -> SSIDProxyProfile? {
        profiles.first { $0.ssid == ssid }
    }
    
    /// 프로필 추가 또는 업데이트
    func saveProfile(ssid: String, ip: String, port: String) {
        if let index = profiles.firstIndex(where: { $0.ssid == ssid }) {
            // 기존 프로필 업데이트
            profiles[index].ip = ip
            profiles[index].port = port
            profiles[index].lastUsed = Date()
        } else {
            // 새 프로필 추가
            let newProfile = SSIDProxyProfile(ssid: ssid, ip: ip, port: port)
            profiles.insert(newProfile, at: 0)
        }
        saveProfiles()
    }
    
    /// 프로필 삭제
    func removeProfile(ssid: String) {
        profiles.removeAll { $0.ssid == ssid }
        saveProfiles()
    }
    
    /// 모든 프로필 삭제
    func removeAllProfiles() {
        profiles = []
        saveProfiles()
    }
}

/// 프록시 설정 데이터 모델
struct ProxySettings: Codable, Equatable {
    var ip: String
    var port: String
    var networkService: String
    var isEnabled: Bool
    
    static let empty = ProxySettings(ip: "", port: "", networkService: "", isEnabled: false)
}

/// 앱 설정 모델
struct AppSettings: Codable {
    var turnOffProxyOnExit: Bool = true
    var showStatusInMenuBar: Bool = true
    var lastUsedNetworkService: String = ""
    var autoApplySSIDProfile: Bool = true  // SSID 프로필 자동 적용 옵션
}
