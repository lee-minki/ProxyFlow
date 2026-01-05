/// ProxyFlow 앱 버전 정보
struct AppVersion {
    static let major = 0
    static let minor = 0
    static let patch = 3
    
    static var string: String {
        "\(major).\(minor).\(patch)"
    }
    
    static var fullString: String {
        "v\(string)"
    }
}
