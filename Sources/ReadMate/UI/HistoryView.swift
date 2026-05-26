import SwiftUI

public struct HistoryView: View {
    @ObservedObject private var historyService = HistoryService.shared
    @State private var searchQuery: String = ""
    
    let onSelectLookup: (WordLookup) -> Void
    
    public init(onSelectLookup: @escaping (WordLookup) -> Void) {
        self.onSelectLookup = onSelectLookup
    }
    
    private var filteredLookups: [WordLookup] {
        if searchQuery.isEmpty {
            return historyService.lookups
        }
        return historyService.lookups.filter {
            $0.selectedText.localizedCaseInsensitiveContains(searchQuery) ||
            ($0.result?.simpleMeaning.localizedCaseInsensitiveContains(searchQuery) ?? false) ||
            ($0.result?.vietnameseMeaning.localizedCaseInsensitiveContains(searchQuery) ?? false)
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Lookup History")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if !historyService.lookups.isEmpty {
                    Button(action: historyService.clearHistory) {
                        Text("Clear All")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    .help("Clear entire search history")
                }
            }
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 13))
                
                TextField("Search history...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.06))
            .cornerRadius(8)
            
            // List contents
            if filteredLookups.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: searchQuery.isEmpty ? "clock.arrow.circlepath" : "doc.text.magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundColor(.gray.opacity(0.6))
                    Text(searchQuery.isEmpty ? "Your history is empty." : "No matching lookups found.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    Text(searchQuery.isEmpty ? "Lookups you trigger using shortcut will appear here." : "Try adjusting your search query.")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredLookups) { lookup in
                            HistoryRow(lookup: lookup, onSelect: {
                                onSelectLookup(lookup)
                            }, onDelete: {
                                historyService.deleteLookup(id: lookup.id)
                            })
                        }
                    }
                    .padding(.trailing, 4)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct HistoryRow: View {
    let lookup: WordLookup
    let onSelect: () -> Void
    let onDelete: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(lookup.selectedText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let mode = lookup.result {
                        Text(mode.vietnameseMeaning)
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(timeAgoString(from: lookup.createdAt))
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.7))
                    
                    if lookup.sourceApp != "Unknown" && !lookup.sourceApp.isEmpty {
                        Text("•")
                            .font(.system(size: 9))
                            .foregroundColor(.gray.opacity(0.4))
                        
                        Text(lookup.sourceApp)
                            .font(.system(size: 10))
                            .foregroundColor(.blue.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.8))
                        .font(.system(size: 11))
                        .padding(6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(isHovering ? 0.08 : 0.03))
        .cornerRadius(8)
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                self.isHovering = hovering
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
