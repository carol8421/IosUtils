//
//  URLExtensions.swift
//  PDFSignature
//
//  Created by woko on 01/08/2018.
//  Copyright Â© 2018 rajeejones. All rights reserved.
//

import Foundation

public extension URL {
    public var queryDictionary: [String: String] {
        var queryStrings = [String: String]()
        
        guard let query = URLComponents(string: self.absoluteString)?.query else { return queryStrings }        
        
        for pair in query.components(separatedBy: "&") {
            
            let key = pair.components(separatedBy: "=")[0]
            
            let value = pair
                .components(separatedBy:"=")[1]
                .replacingOccurrences(of: "+", with: " ")
                .removingPercentEncoding ?? ""
            
            queryStrings[key] = value
        }
        return queryStrings
    }
    
    public func readFile() -> Data? {
        if let data = NSData(contentsOfFile: self.path) {
            return data as Data
        }
        return nil
    }
    
    public var fileSize: Int {
        get {
            let attr = try? FileManager.default.attributesOfItem(atPath: self.path)
            if let attr = attr, let fileSize = attr[FileAttributeKey.size] as? UInt64 {
                return Int(fileSize)
            }
            return -1
        }
    }
    
    public func readFirst(_ toRead:Int) -> Data? {
        if let file = try? FileHandle(forReadingFrom: self) {
            let data = file.readData(ofLength: toRead)
            return data
        }
        return nil
    }
    
    public func readLast(_ toRead:Int) -> Data? {
        if let file = try? FileHandle(forReadingFrom: self) {
            let length = file.seekToEndOfFile()
            if length >= toRead {
                file.seek(toFileOffset: length.advanced(by: -toRead))
                return file.readDataToEndOfFile()
            }
        }
        return nil
    }
}
