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
    
    func append(fileURL: URL) throws {
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
}

public extension Int {
    public func to(_ val:Int) -> [Int] {
        if val <= self {
            return []
        }
        return Array(stride(from: self, to: val, by: 1))
    }
}
