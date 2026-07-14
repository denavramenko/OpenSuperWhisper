import Foundation

final class BrainFlowIntegrationSender {
    static let shared = BrainFlowIntegrationSender()

    private let endpoint = URL(string: "http://localhost:8765/api/integrations/ingest")!

    func send(
        audioURL: URL,
        transcription: String,
        recordingId: String,
        clipboardText: String? = nil
    ) async -> (processed: String?, error: String?) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: Date())
        let transcriptionPrefix = String(transcription.prefix(30))

        var content: [String: Any] = [
            "text": transcription,
            "audioSourcePath": audioURL.path,
        ]

        var payload: [String: Any] = [
            "eid": recordingId,
            "brain": "voice",
            "nodeType": "Interaction",
            "name": "\(dateString)\(transcriptionPrefix.isEmpty ? "" : " - \(transcriptionPrefix)")",
            "content": content,
        ]

        if let clipboardText = clipboardText, !clipboardText.isEmpty {
            payload["context"] = [
                "text": clipboardText,
                "source": "clipboard",
            ]
        }

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            let message = "Failed to encode BrainFlow integration payload"
            print(message)
            return (nil, message)
        }

        if let json = String(data: body, encoding: .utf8) {
            print("BrainFlow integration request: \(json)")
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("BrainFlow integration status: \(httpResponse.statusCode)")
            }
            if let responseBody = String(data: data, encoding: .utf8) {
                print("BrainFlow integration response: \(responseBody)")
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return (nil, nil)
            }

            if let success = json["success"] as? Bool, !success,
               let errorMessage = json["error"] as? String {
                return (nil, errorMessage)
            }

            if let processing = json["processing"] as? [String: Any] {
                if processing["success"] as? Bool == true,
                   let processed = processing["processed"] as? String {
                    return (processed, nil)
                }
                if let errorMessage = processing["error"] as? String {
                    return (nil, errorMessage)
                }
            }

            return (nil, nil)
        } catch {
            let message = "Failed to send transcription to BrainFlow: \(error.localizedDescription)"
            print(message)
            return (nil, message)
        }
    }
}
