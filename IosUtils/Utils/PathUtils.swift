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
    
    static public func removeAfterSubstring(_ path:String, substring:String) -> String {
        var res = path
        let index = res.range(of:"/", options:.backwards)?.lowerBound
        if let index = index {
            res = String(res[..<index])
        }
        return res
    }
    
    static public func splitPath(_ path:String) -> [String] {
        var path = stripLeadingSlashes(path)
        path = stripTrailingSlashes(path)
        return path.components(separatedBy: "/").filter { !$0.isEmpty }
    }
}
