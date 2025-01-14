import Foundation

class StationsCache {
    static let shared = StationsCache()
    private let cacheKey = "cached_stations"
    private let lastUpdateKey = "stations_last_update"
    
    private init() {}
    
    var cachedStations: [Station]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode([Station].self, from: data)
    }
    
    var lastUpdate: Date? {
        return UserDefaults.standard.object(forKey: lastUpdateKey) as? Date
    }
    
    func saveStations(_ stations: [Station]) {
        guard let encoded = try? JSONEncoder().encode(stations) else { return }
        UserDefaults.standard.set(encoded, forKey: cacheKey)
        UserDefaults.standard.set(Date(), forKey: lastUpdateKey)
    }
    
    func shouldRefresh() -> Bool {
        guard let lastUpdate = lastUpdate else { return true }
        return Date().timeIntervalSince(lastUpdate) > 24 * 3600 // 24 hours
    }
}
