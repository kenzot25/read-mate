import Foundation

@MainActor
public class HistoryService: ObservableObject {
    public static let shared = HistoryService()
    
    @Published public var lookups: [WordLookup] = []
    
    private let fileManager = FileManager.default
    
    private var historyURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("com.readmate.ReadMate", isDirectory: true)
        
        // Ensure folder exists
        if !fileManager.fileExists(atPath: appDir.path) {
            try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        return appDir.appendingPathComponent("history.json")
    }
    
    private init() {
        loadHistory()
    }
    
    public func loadHistory() {
        let url = historyURL
        guard fileManager.fileExists(atPath: url.path) else {
            self.lookups = []
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode([WordLookup].self, from: data)
            
            // Dispatch update to main thread for SwiftUI observation
            DispatchQueue.main.async {
                self.lookups = decoded.sorted(by: { $0.createdAt > $1.createdAt })
            }
        } catch {
            print("[HistoryService] Failed to decode history: \(error)")
            self.lookups = []
        }
    }
    
    public func addLookup(_ lookup: WordLookup) {
        DispatchQueue.main.async {
            // Remove previous instances of the same query to keep history clean and unique
            self.lookups.removeAll(where: { $0.selectedText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == lookup.selectedText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
            
            // Insert newest at top
            self.lookups.insert(lookup, at: 0)
            self.saveHistory()
        }
    }
    
    public func deleteLookup(id: UUID) {
        DispatchQueue.main.async {
            self.lookups.removeAll(where: { $0.id == id })
            self.saveHistory()
        }
    }
    
    public func clearHistory() {
        DispatchQueue.main.async {
            self.lookups.removeAll()
            self.saveHistory()
        }
    }
    
    private func saveHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(lookups)
            try data.write(to: historyURL, options: .atomic)
        } catch {
            print("[HistoryService] Failed to save history: \(error)")
        }
    }
}
