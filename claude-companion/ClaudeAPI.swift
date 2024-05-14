import Foundation

class ClaudeAPI {
    private let apiKey = "API CODE HERE"
    private let baseURL = "https://api.anthropic.com/v1/messages"
    
    func getResponseFromClaude(message: String, completion: @escaping (Data?) -> Void) {
            guard let url = URL(string: baseURL) else {
                completion(nil)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("\(apiKey)", forHTTPHeaderField: "x-api-key")
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

            let requestBody: [String: Any] = [
                "model": "claude-3-opus-20240229",
                "max_tokens": 1024,
                "messages": [
                    ["role": "user", "content": message]
                ]
            ]

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
                request.httpBody = jsonData
            } catch {
                print("Error serializing JSON: \(error)")
                completion(nil)
                return
            }

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("Response Status Code: \(httpResponse.statusCode)")

                    if !(200...299).contains(httpResponse.statusCode) {
                        print("Server responded with error: \(httpResponse.statusCode)")
                        completion(nil)
                        return
                    }
                }

                completion(data)
            }

            task.resume()
        }
}
