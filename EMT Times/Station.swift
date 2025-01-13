import Foundation
import CoreLocation

struct StationResponse: Codable {
    let code: String
    let data: [Station]
    let description: String
    let datetime: String
}

struct LoginResponse: Codable {
    let code: String
    let description: String
    let datetime: String
    let data: [LoginData]
}

struct LoginData: Codable {
    let accessToken: String
    let nameApp: String
    let levelApp: Int
    let userName: String
    let idUser: String
    let email: String
    let apiCounter: ApiCounter
    // Other fields can be added if needed
}

struct ApiCounter: Codable {
    let current: Int
    let dailyUse: Int
    let owner: Int
    let licenceUse: String
}

struct Station: Codable, Identifiable {
    let id: String
    let name: String
    let coordinates: CLLocationCoordinate2D
    let wifi: String
    let lines: [String]
    
    enum CodingKeys: String, CodingKey {
        case id = "node"
        case name
        case geometry
        case wifi
        case lines
    }
    
    enum GeometryKeys: String, CodingKey {
        case coordinates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        wifi = try container.decode(String.self, forKey: .wifi)
        lines = try container.decode([String].self, forKey: .lines)
        
        let geometryContainer = try container.nestedContainer(keyedBy: GeometryKeys.self, forKey: .geometry)
        let coordinateArray = try geometryContainer.decode([Double].self, forKey: .coordinates)
        coordinates = CLLocationCoordinate2D(latitude: coordinateArray[1], longitude: coordinateArray[0])
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(wifi, forKey: .wifi)
        try container.encode(lines, forKey: .lines)
        
        var geometryContainer = container.nestedContainer(keyedBy: GeometryKeys.self, forKey: .geometry)
        try geometryContainer.encode([coordinates.longitude, coordinates.latitude], forKey: .coordinates)
    }
}

struct StopDetailResponse: Codable {
    let code: String
    let data: [StopDetailData]
    let description: String
    let datetime: String
}

struct StopDetailData: Codable {
    let stops: [StopDetail]
}

struct StopDetail: Codable {
    let name: String
    let geometry: Geometry
    let stop: String
    let dataLine: [LineDetail]
    let postalAddress: String
}

struct Geometry: Codable {
    let type: String
    let coordinates: [Double]
}

struct LineDetail: Codable {
    let headerB: String
    let direction: String
    let headerA: String
    let label: String
    let stopTime: String
    let minFreq: String
    let startTime: String
    let maxFreq: String
    let dayType: String
    let line: String
}

struct ArrivalResponse: Codable {
    let code: String
    let description: String
    let datetime: String
    let data: [ArrivalData]
}

struct ArrivalData: Codable {
    let Arrive: [Arrival]
    let StopInfo: [StopInfo]
}

struct Arrival: Codable, Identifiable {
    var id: String { "\(line)-\(bus)" }
    let line: String
    let stop: String
    let destination: String
    let estimateArrive: Int
    let DistanceBus: Int
    let bus: Int
}

struct StopInfo: Codable {
    let lines: [LineInfo]
    let stopId: String
    let stopName: String
    let Direction: String
}

struct LineInfo: Codable {
    let label: String
    let line: String
    let nameA: String
    let nameB: String
    let to: String
}
