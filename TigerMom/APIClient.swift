import Foundation

final class APIClient: Sendable {
    static let shared = APIClient()

    private let baseURL = "http://localhost:8000"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
    }

    // MARK: - Health

    func health() async throws -> [String: Any] {
        try await get("/health")
    }

    // MARK: - Screenshot (multipart upload)

    func uploadScreenshot(imageData: Data) async throws -> [String: Any] {
        let url = URL(string: baseURL + "/screenshot")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"screenshot\"; filename=\"screenshot.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, _) = try await session.data(for: request)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }

    // MARK: - Nudge

    func getNudge() async throws -> [String: Any] {
        try await get("/nudge")
    }

    func nudgeResponse(body: [String: Any]) async throws -> [String: Any] {
        try await post("/nudge/response", body: body)
    }

    // MARK: - Chat

    func chat(message: String) async throws -> [String: Any] {
        try await post("/chat", body: ["content": message])
    }

    func chatHistory() async throws -> [String: Any] {
        try await get("/chat/history")
    }

    // MARK: - Activities

    func activities() async throws -> [String: Any] {
        try await get("/activities")
    }

    func getActivities(page: Int, limit: Int, category: String? = nil) async throws -> [String: Any] {
        var path = "/activities?page=\(page)&limit=\(limit)"
        if let category {
            path += "&category=\(category)"
        }
        return try await get(path)
    }

    // MARK: - Analytics

    func analyticsDaily() async throws -> [String: Any] {
        try await get("/analytics/daily")
    }

    func analyticsWeekly() async throws -> [String: Any] {
        try await get("/analytics/weekly")
    }

    func analyticsTimeline() async throws -> [String: Any] {
        try await get("/analytics/timeline")
    }

    // MARK: - Settings

    func getSettings() async throws -> [String: Any] {
        try await get("/settings")
    }

    func updateSettings(body: [String: Any]) async throws -> [String: Any] {
        try await post("/settings", body: body)
    }

    // MARK: - Models

    func availableModels() async throws -> [String: Any] {
        try await get("/models/available")
    }

    // MARK: - Settings extras

    func testApiKey(key: String) async throws -> [String: Any] {
        try await post("/settings/test-key", body: ["api_key": key])
    }

    func clearData() async throws -> [String: Any] {
        try await post("/settings/clear-data")
    }

    func exportData() async throws -> [String: Any] {
        try await get("/settings/export")
    }

    // MARK: - Private

    private func get(_ path: String) async throws -> [String: Any] {
        let url = URL(string: baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, _) = try await session.data(for: request)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }

    private func post(_ path: String, body: [String: Any]? = nil) async throws -> [String: Any] {
        let url = URL(string: baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, _) = try await session.data(for: request)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
}
