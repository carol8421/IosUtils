import UIKit

public class StringUtils {

    public static func XXHASH(_ string: String) -> String {
        let state = XXHash(seed: 0)
        let buffer:[UInt8] = Array(string.utf8)
        
        state.update(buffer: buffer)
        
        let hash = state.digest()
        return String(format: "%lx", hash)
    }
    
    public static func GetFileFromPath(_ path:String) -> String {
        var res = path
        let index = res.range(of:"/", options:.backwards)?.upperBound
        if let index = index {
            res = String(res[index...])
        }
        return res
    }
    
    public static func ParseInt(_ text:String, maxLen:Int = Int.max) -> Int {
        let len = min(maxLen,text.count)
        var val = 0
        for i in 0..<len {
            let ch = text.sub(i).first!.ascii
            if let ch = ch {
                if ch >= 48 && ch <= 57 {
                    val = val * 10 + Int(ch - 48)
                }
            }
        }
        return val
    }
    
    public static func EscapeSqliteQuotes(_ text:String) -> String {
        return text.replacingOccurrences(of: "'", with: "''")
    }
    
    public static func EscapeSqliteDoubleQuotes(_ text:String) -> String {
        return text.replacingOccurrences(of: "\"", with: "\"\"")
    }
    
    public static func EscapeSqliteSearchTerm(_ text:String) -> String {
        return text.split(separator: " ").filter { $0.count > 0 }.map { $0 + "*"}.joined(separator: " ").replacingOccurrences(of: "\"", with: "\"\"")
    }
    
    public static func EscapeSqliteVar(_ text:String) -> String {
        return text.replacingOccurrences(of: "'", with: "''").replacingOccurrences(of: "\"", with: "\"\"")
    }
    
    public static func GetSearchTerms(_ text:String) -> [String] {
        return text.split(separator: " ").filter { $0.count > 1 }.map { $0.lowercased() }
    }
    
    public static func HasSearchTerms(_ text:String) -> Bool {
        return GetSearchTerms(text).count > 0
    }
}
