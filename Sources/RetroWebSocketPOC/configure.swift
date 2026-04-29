import Vapor
import Foundation

public func configure(_ app: Application) async throws {
    
    app.http.server.configuration.hostname = "0.0.0.0"
    
    try routes(app)
    
    let ip = getMacIP()
    print("\n=========================================================")
    print("🚀 SERVIDOR RETRO RODANDO!")
    print("📡 SEU IP DE REDE (MACIP): \(ip)")
    print("👉 Passe este IP para os seus miguxos colocarem no app!")
    print("=========================================================\n")
}

func getMacIP() -> String {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/sbin/ipconfig")
    task.arguments = ["getifaddr", "en0"]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    
    do {
        try task.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let ip = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !ip.isEmpty {
            return ip
        }
    } catch {
        print("Erro ao buscar IP: \(error)")
    }
    
    return "127.0.0.1 (IP não encontrado, verifique se o Wi-Fi está ligado)"
}
