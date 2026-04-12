import XCTest
@testable import TigerMom

// MARK: - ChatMessage Tests

final class ChatMessageTests: XCTestCase {

    func testChatMessageInitialization() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let msg = ChatMessage(id: "msg-1", content: "Hello", isUser: true, timestamp: date)

        XCTAssertEqual(msg.id, "msg-1")
        XCTAssertEqual(msg.content, "Hello")
        XCTAssertTrue(msg.isUser)
        XCTAssertEqual(msg.timestamp, date)
    }

    func testChatMessageEquality() {
        let date = Date()
        let a = ChatMessage(id: "same-id", content: "Hello", isUser: true, timestamp: date)
        let b = ChatMessage(id: "same-id", content: "Different content", isUser: false, timestamp: date.addingTimeInterval(100))

        // Equality is based solely on id
        XCTAssertEqual(a, b)
    }

    func testChatMessageInequality() {
        let date = Date()
        let a = ChatMessage(id: "id-1", content: "Hello", isUser: true, timestamp: date)
        let b = ChatMessage(id: "id-2", content: "Hello", isUser: true, timestamp: date)

        XCTAssertNotEqual(a, b)
    }

    func testChatMessageIdentifiable() {
        let msg = ChatMessage(id: "unique-id", content: "Test", isUser: false, timestamp: Date())
        XCTAssertEqual(msg.id, "unique-id")
    }

    func testUserMessage() {
        let msg = ChatMessage(id: "u1", content: "How am I doing?", isUser: true, timestamp: Date())
        XCTAssertTrue(msg.isUser)
    }

    func testAssistantMessage() {
        let msg = ChatMessage(id: "a1", content: "You're doing great!", isUser: false, timestamp: Date())
        XCTAssertFalse(msg.isUser)
    }

    func testEmptyContent() {
        let msg = ChatMessage(id: "e1", content: "", isUser: true, timestamp: Date())
        XCTAssertEqual(msg.content, "")
    }
}

// MARK: - ChatStatsSnapshot Tests

final class ChatStatsSnapshotTests: XCTestCase {

    func testDefaultValues() {
        let stats = ChatStatsSnapshot()
        XCTAssertEqual(stats.focusScore, 0)
        XCTAssertEqual(stats.deepWorkMinutes, 0)
        XCTAssertEqual(stats.distractionMinutes, 0)
        XCTAssertEqual(stats.shallowWorkMinutes, 0)
        XCTAssertEqual(stats.communicationMinutes, 0)
    }

    func testMutability() {
        var stats = ChatStatsSnapshot()
        stats.focusScore = 85
        stats.deepWorkMinutes = 180
        stats.distractionMinutes = 30
        stats.shallowWorkMinutes = 45
        stats.communicationMinutes = 60

        XCTAssertEqual(stats.focusScore, 85)
        XCTAssertEqual(stats.deepWorkMinutes, 180)
        XCTAssertEqual(stats.distractionMinutes, 30)
        XCTAssertEqual(stats.shallowWorkMinutes, 45)
        XCTAssertEqual(stats.communicationMinutes, 60)
    }
}

// MARK: - ChatConnectionStatus Tests

final class ChatConnectionStatusTests: XCTestCase {

    func testCheckingLabel() {
        XCTAssertEqual(ChatConnectionStatus.checking.label, "Checking")
    }

    func testOnlineLabel() {
        XCTAssertEqual(ChatConnectionStatus.online.label, "Connected")
    }

    func testOfflineLabel() {
        XCTAssertEqual(ChatConnectionStatus.offline.label, "Offline")
    }

    func testCheckingSymbol() {
        XCTAssertEqual(ChatConnectionStatus.checking.symbol, "bolt.horizontal.circle")
    }

    func testOnlineSymbol() {
        XCTAssertEqual(ChatConnectionStatus.online.symbol, "checkmark.seal.fill")
    }

    func testOfflineSymbol() {
        XCTAssertEqual(ChatConnectionStatus.offline.symbol, "wifi.slash")
    }

    func testCheckingTint() {
        XCTAssertEqual(ChatConnectionStatus.checking.tint, TigerPalette.gold)
    }

    func testOnlineTint() {
        XCTAssertEqual(ChatConnectionStatus.online.tint, TigerPalette.jade)
    }

    func testOfflineTint() {
        XCTAssertEqual(ChatConnectionStatus.offline.tint, TigerPalette.coral)
    }
}

// MARK: - Chat canSend Logic Tests

final class ChatCanSendTests: XCTestCase {

    // Replicate canSend logic from ChatView
    private func canSend(inputText: String, isSending: Bool) -> Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    func testCanSendWithValidText() {
        XCTAssertTrue(canSend(inputText: "Hello", isSending: false))
    }

    func testCannotSendWhileAlreadySending() {
        XCTAssertFalse(canSend(inputText: "Hello", isSending: true))
    }

    func testCannotSendWithEmptyText() {
        XCTAssertFalse(canSend(inputText: "", isSending: false))
    }

    func testCannotSendWithWhitespaceOnly() {
        XCTAssertFalse(canSend(inputText: "   ", isSending: false))
        XCTAssertFalse(canSend(inputText: "\n\n", isSending: false))
        XCTAssertFalse(canSend(inputText: "\t  \n", isSending: false))
    }

    func testCanSendWithWhitespaceAroundText() {
        XCTAssertTrue(canSend(inputText: "  Hello  ", isSending: false))
    }

    func testCannotSendEmptyAndSending() {
        XCTAssertFalse(canSend(inputText: "", isSending: true))
    }
}

// MARK: - Chat History Parsing Tests

final class ChatHistoryParsingTests: XCTestCase {

    // Replicate the message parsing logic from loadHistory
    private func parseMessages(_ history: [[String: Any]]) -> [ChatMessage] {
        history.compactMap { msg in
            guard let id = msg["id"] as? String,
                  let content = msg["content"] as? String,
                  let isUser = msg["is_user"] as? Bool else { return nil }

            let timestamp = (msg["timestamp"] as? Double).map { Date(timeIntervalSince1970: $0) } ?? Date()
            return ChatMessage(id: id, content: content, isUser: isUser, timestamp: timestamp)
        }
    }

    func testParseValidHistory() {
        let history: [[String: Any]] = [
            ["id": "m1", "content": "Hello", "is_user": true, "timestamp": 1_700_000_000.0],
            ["id": "m2", "content": "Hi there!", "is_user": false, "timestamp": 1_700_000_010.0]
        ]

        let messages = parseMessages(history)
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0].id, "m1")
        XCTAssertEqual(messages[0].content, "Hello")
        XCTAssertTrue(messages[0].isUser)
        XCTAssertEqual(messages[0].timestamp, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(messages[1].id, "m2")
        XCTAssertFalse(messages[1].isUser)
    }

    func testParseMissingIdSkipsMessage() {
        let history: [[String: Any]] = [
            ["content": "Hello", "is_user": true]
        ]
        let messages = parseMessages(history)
        XCTAssertTrue(messages.isEmpty)
    }

    func testParseMissingContentSkipsMessage() {
        let history: [[String: Any]] = [
            ["id": "m1", "is_user": true]
        ]
        let messages = parseMessages(history)
        XCTAssertTrue(messages.isEmpty)
    }

    func testParseMissingIsUserSkipsMessage() {
        let history: [[String: Any]] = [
            ["id": "m1", "content": "Hello"]
        ]
        let messages = parseMessages(history)
        XCTAssertTrue(messages.isEmpty)
    }

    func testParseMissingTimestampUsesCurrentDate() {
        let before = Date()
        let history: [[String: Any]] = [
            ["id": "m1", "content": "Hello", "is_user": true]
        ]
        let messages = parseMessages(history)
        let after = Date()

        XCTAssertEqual(messages.count, 1)
        XCTAssertGreaterThanOrEqual(messages[0].timestamp, before)
        XCTAssertLessThanOrEqual(messages[0].timestamp, after)
    }

    func testParseEmptyHistory() {
        let messages = parseMessages([])
        XCTAssertTrue(messages.isEmpty)
    }

    func testParseMixedValidAndInvalid() {
        let history: [[String: Any]] = [
            ["id": "m1", "content": "Valid", "is_user": true],
            ["id": "m2"],  // missing content and is_user
            ["id": "m3", "content": "Also valid", "is_user": false]
        ]
        let messages = parseMessages(history)
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0].id, "m1")
        XCTAssertEqual(messages[1].id, "m3")
    }
}

// MARK: - Suggested Prompts Tests

final class SuggestedPromptsTests: XCTestCase {

    func testSuggestedPromptsExist() {
        let prompts = [
            "How am I doing today?",
            "What should I focus on next?",
            "Be brutally honest with me.",
            "What keeps distracting me?"
        ]
        XCTAssertEqual(prompts.count, 4)
        for prompt in prompts {
            XCTAssertFalse(prompt.isEmpty)
        }
    }
}
