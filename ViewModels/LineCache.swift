import Foundation

class LineCache {
    static let shared = LineCache()
    private let cacheKey = "lineCacheKey"
    private let lastUpdateKey = "lineCacheLastUpdateKey"
    private var memoryCache: [LineDetail]?
    
    var cachedLines: [LineDetail]? {
        if let memoryCache = memoryCache {
            return memoryCache
        }
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([LineDetail].self, from: data) {
            memoryCache = decoded
            return decoded
        }
        return nil
    }
    
    var lastUpdate: Date? {
        UserDefaults.standard.object(forKey: lastUpdateKey) as? Date
    }
    
    func shouldRefresh() -> Bool {
        guard let lastUpdate = lastUpdate else { return true }
        return Calendar.current.dateComponents([.day], from: lastUpdate, to: Date()).day ?? 0 > 30
    }
    
    func saveLines(_ lines: [LineDetail]) {
        memoryCache = lines
        if let encoded = try? JSONEncoder().encode(lines) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: lastUpdateKey)
        }
    }
    
    func clearMemoryCache() {
        memoryCache = nil
    }
    
    private init() {}
}
