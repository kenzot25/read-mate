import Foundation

public enum AIError: Error, LocalizedError {
    case missingApiKey
    case invalidResponse
    case apiError(String)
    
    public var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "Please enter a valid Gemini API Key in the Settings tab."
        case .invalidResponse:
            return "Failed to parse the response from the Gemini API."
        case .apiError(let message):
            return message
        }
    }
}

public final class AIService: Sendable {
    public static let shared = AIService()
    
    private init() {}
    
    /// Queries the Gemini API to explain the selected text based on the provided template instruction.
    public func explain(text: String, template: AITemplate) async throws -> LookupResult {
        // 1. Retrieve the Gemini API Key from secure Keychain
        guard let apiKey = KeychainManager.shared.retrieve(), !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AIError.missingApiKey
        }
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw AIError.apiError("Invalid API Endpoint URL configuration.")
        }
        
        // 2. Build the context prompt
        let promptText = """
        You are ReadMate, a supportive language learning assistant for Vietnamese users learning English.
        Analyze the following text according to this template instruction: "\(template.promptInstruction)"
        
        Selected Text to analyze:
        \"\"\"
        \(text)
        \"\"\"
        
        Ensure your explanations are accurate, professional, and clear. Under the responseSchema, populate:
        - 'simpleMeaning': explaining the core concept in simple, clear English.
        - 'vietnameseMeaning': providing a natural translation or localized explanation.
        - 'examples': exactly 3 clear example sentences.
        - 'grammar': structural notes (optional, if relevant).
        - 'vocabulary': word-by-word breakdowns if the input is a phrase/sentence (optional).
        - 'aiNotes': specific formatting notes requested by the template (like Anki cards or ELI5 analogies).
        """
        
        // 3. Build the request payload incorporating responseSchema
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": promptText]
                    ]
                ]
            ],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": [
                    "type": "OBJECT",
                    "properties": [
                        "simpleMeaning": [
                            "type": "STRING",
                            "description": "Very simple explanation of the selected text in English."
                        ],
                        "vietnameseMeaning": [
                            "type": "STRING",
                            "description": "Natural translation and explanation in Vietnamese."
                        ],
                        "examples": [
                            "type": "ARRAY",
                            "items": ["type": "STRING"],
                            "description": "Exactly 3 short, clear, and natural example sentences."
                        ],
                        "grammar": [
                            "type": "STRING",
                            "description": "A brief structural/grammar explanation of the selected text, if applicable."
                        ],
                        "vocabulary": [
                            "type": "ARRAY",
                            "items": [
                                "type": "OBJECT",
                                "properties": [
                                    "word": ["type": "STRING"],
                                    "meaning": ["type": "STRING", "description": "Simple English meaning."],
                                    "vietnamese": ["type": "STRING", "description": "Vietnamese meaning."],
                                    "example": ["type": "STRING", "description": "A brief example sentence."]
                                ],
                                "required": ["word", "meaning", "vietnamese", "example"]
                            ],
                            "description": "Breakdown of complex or key vocabulary words inside the text."
                        ],
                        "aiNotes": [
                            "type": "STRING",
                            "description": "Custom template notes (like Front/Back for Anki, ELI5 simple analogies, or cultural context notes)."
                        ]
                    ],
                    "required": ["simpleMeaning", "vietnameseMeaning", "examples"]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // 4. Perform the network request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        // 5. Handle potential API errors
        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorDict = errorJson["error"] as? [String: Any],
               let errorMessage = errorDict["message"] as? String {
                throw AIError.apiError(errorMessage)
            }
            throw AIError.apiError("Gemini API returned status code: \(httpResponse.statusCode)")
        }
        
        // 6. Extract candidate text output
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let textContent = firstPart["text"] as? String else {
            throw AIError.invalidResponse
        }
        
        // 7. Decode the structured JSON returned by the AI into our typed model
        guard let textData = textContent.data(using: .utf8) else {
            throw AIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(LookupResult.self, from: textData)
    }
}
