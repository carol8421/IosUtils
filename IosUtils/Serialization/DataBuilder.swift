//
//  DataBuilder.swift
//  Networkamp
//
//  Created by woko on 26/06/2018.
//  Copyright © 2018 Pandastic Games. All rights reserved.
//

import UIKit

public class DataBuilder {
    var data: [UInt8] = []
    
    public func appendBool(_ item:Bool?) {
        let item = item ?? false
        data.append((item ? 1 : 0) as UInt8)
    }
    
    public func appendInt8(_ item:Int) {
        let res = abs(item) & 0x7f | (item >= 0 ? 0x80 : 0) //7 bits + sign
        data.append(UInt8(res))
    }
    
    public func appendUInt8(_ item:Int) {
        data.append(UInt8(item & 0xff))
    }
    
    public func appendInt(_ item:Int){
        appendUInt8(DataBuilder.int3(item))
        appendUInt8(DataBuilder.int2(item))
        appendUInt8(DataBuilder.int1(item))
        appendUInt8(DataBuilder.int0(item))
    }
    
    public func appendString(_ item:String?) {
        if let item = item {
            let itemData: [UInt8] = [UInt8](item.utf8)
            appendInt(itemData.count)
            for ch in itemData {
                data.append(ch)
            }
        } else {
            appendInt(DataReader.INT32MAX)
        }
    }
    
    public func toByteArray() -> [UInt8] {
        return data
    }
    
    public func toData() -> Data {
        var res = Data()
        res.append(contentsOf: data)
        return res
    }
    
    static func int3(_ x:Int) -> Int {
        return (abs(x) >> 24) & 0xff;
    }
    
    static func int2(_ x:Int) -> Int {
        return (abs(x) >> 16) & 0xff;
    }
    
    static func int1(_ x:Int) -> Int {
        return (abs(x) >> 8) & 0xff;
    }
    
    static func int0(_ x:Int) -> Int {
        return abs(x) & 0xff;
    }
}
