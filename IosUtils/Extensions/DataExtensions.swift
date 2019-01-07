//
//  DataExtensions.swift
//  IosUtils
//
//  Created by woko on 10/09/2018.
//  Copyright © 2018 Woko. All rights reserved.
//

import Foundation

public extension Data {
    public func appendTo(fileURL: URL) -> Bool {
        do {
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                defer {
                    fileHandle.closeFile()
                }
                fileHandle.seekToEndOfFile()
                try fileHandle.write(self)
            }
            else {
                try write(to: fileURL, options: .atomic)
            }
            return true
        } catch {
            return false
        }
    }
    
    public init(arr:[UInt8]) {
        self.init()
        self.append(contentsOf: arr)
    }
    
    public func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else {
            try write(to: fileURL, options: .atomic)
        }
    }
    
    public func toHex() -> String {
        return map { String(format: "%02hhX", $0) }.joined()
    }
    
    public func toHex(from:Int, to:Int) -> String {
        return self.subdata(in: from..<to).toHex()
    }
    
    public func toArrayUInt8() -> [UInt8] {
        var array = [UInt8]()
        self.withUnsafeBytes {  (pointer: UnsafePointer<UInt8>) in
            array = Array(UnsafeBufferPointer(start: pointer, count: self.count))
        }
        return array
    }
    
    static public func fromArrayUInt8(_ arr:[UInt8]) -> Data {
        var data = Data()
        data.append(contentsOf: arr)
        return data
    }
}

public extension Int {
    public func to(_ val:Int) -> [Int] {
        if val <= self {
            return []
        }
        return Array(stride(from: self, to: val, by: 1))
    }
}
