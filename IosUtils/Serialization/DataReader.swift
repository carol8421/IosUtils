//
//  DataReader.swift
//  Networkamp
//
//  Created by woko on 26/06/2018.
//  Copyright © 2018 Pandastic Games. All rights reserved.
//

import UIKit

public class DataReader {
    var data: [UInt8] = []
    var pos = 0
    
    public static let INT32MAX = 2147483647
    
    public init(data:[UInt8]) {
        self.data = data
    }
    
    public init(data:NSData) {
        self.data = [UInt8](data as Data)
    }
    
    public init(data:Data) {
        self.data = [UInt8](data)
    }
    
    public func readBool() throws -> Bool {
        if !canRead(1) {
            throw DataReaderError.InvalidInput
        }
        let res = data[pos] == 1
        pos += 1
        return res
    }
    
    public func readInt8() throws -> Int {
        if !canRead(1) {
            throw DataReaderError.InvalidInput
        }
        let res = Int(data[pos])
        pos += 1
        return (res & 0x7f) * ((res & 0x80) > 0 ? 1 : -1)
    }
    
    public func readUInt8() throws -> Int {
        if !canRead(1) {
            throw DataReaderError.InvalidInput
        }
        let res = data[pos]
        pos += 1
        return Int(res)
    }
    
    public func readInt() throws -> Int {
        if !canRead(4) {
            throw DataReaderError.InvalidInput
        }
        let res = Int(data[pos]) << 24 | Int(data[pos+1]) << 16 | Int(data[pos+2]) << 8 | Int(data[pos+3])
        pos += 4
        return res
    }
    
    public func readString() throws -> String {
        if let res = try readStringNullable() {
            return res
        }
        return ""
    }
    
    public func readStringNullable() throws -> String? {
        if !canRead(4) {
            throw DataReaderError.InvalidInput
        }
        let len = try readInt()
        
        if len == DataReader.INT32MAX || len < 0 {
            return nil
        }
        
        if !canRead(len) {
            throw DataReaderError.InvalidInput
        }
        
        var res: [UInt8] = []
        for _ in 0.to(len) {
            res.append(data[pos])
            pos += 1
        }
        guard let result = String(bytes: res, encoding: .utf8) else {
            throw DataReaderError.InvalidString
        }
        return result
    }
    
    func canRead(_ length:Int) -> Bool {
        return (pos + length) <= data.count
    }
    
    enum DataReaderError: Error {
        case InvalidInput
        case InvalidString
    }
}
