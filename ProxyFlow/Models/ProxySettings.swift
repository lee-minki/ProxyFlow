import Foundation

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
}
