import Foundation

public extension JSONEncoder {
    public static func encodeString<T: Encodable>(_ value: T, options opt: JSONSerialization.ReadingOptions = []) -> String {
        let data = try? JSONEncoder().encode(value)
        
        if let data2 = data {
            return String(data: data2, encoding: .utf8)!
        }
        return ""
    }
}

public extension JSONDecoder {
    public static func decodeData<T: Decodable>(_ type: T.Type, from:Data) -> T? {
        return try? JSONDecoder().decode(type,from:from)
    }
    
    public static func decodeString<T: Decodable>(_ type: T.Type, from:String) -> T? {
        return try? JSONDecoder().decode(type,from:from.utf8Encoded)
    }
}
