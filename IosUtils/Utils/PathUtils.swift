//
//  PathUtils.swift
//  Networkamp
//
//  Created by woko on 03/08/2018.
//  Copyright © 2018 Pandastic Games. All rights reserved.
//

import Foundation

public class PathUtils {
    static public func ensureTrailingSlash(_ path:String) -> String {
        return path.hasSuffix("/") ? path : path+"/"
    }
    
    static public func stripLeadingSlashes(_ path:String) -> String {
        var res = path
        while res.hasPrefix("/") {
            res.remove(at: res.startIndex)
        }
        return String(res)
    }
    
    static public func stripTrailingSlashes(_ path:String) -> String {
        var res = path
        while res.hasSuffix("/") {
            res = String(res[..<res.index(res.endIndex, offsetBy: -1)])
        }
        return res
    }
    
    static public func stripSlashes(_ path:String) -> String {
        return stripLeadingSlashes(stripTrailingSlashes(path))
    }
    
    static public func removeAfterSubstring(_ path:String, substring:String) -> String {
        var res = path
        let index = res.range(of:"/", options:.backwards)?.lowerBound
        if let index = index {
            res = String(res[..<index])
        }
        return res
    }
    
    static public func separateFileNameExtension(_ filename:String) -> (String,String?) {
        var components = filename.components(separatedBy: ".")
        guard components.count > 1 else { return (filename,nil) }
        let ext = components.last!
        components.removeLast()
        return (components.joined(separator: "."),ext)
    }
    
    static public func addFileNameSuffix(_ filename:String, suffix:String) -> String {
        let res = separateFileNameExtension(filename)
        
        if let ext = res.1 {
            return res.0 + suffix + "." + ext
        } else {
            return filename + suffix
        }
    }
    
    public static func sanitizePathComponent(_ name:String) -> String {
        return name.replacingOccurrences(of: "/", with: "_")
    }
    
    static public func splitPath(_ path:String) -> [String] {
        var path = stripLeadingSlashes(path)
        path = stripTrailingSlashes(path)
        return path.components(separatedBy: "/").filter { !$0.isEmpty }
    }
    
    static public func getFreeSpace() -> Int64? {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                return capacity
            }
        } catch {
            print("Error retrieving capacity: \(error.localizedDescription)")
        }
        return nil
    }
}
