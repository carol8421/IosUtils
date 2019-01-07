//
//  BinaryCodable.swift
//  IosUtils
//
//  Created by woko on 01/10/2018.
//  Copyright © 2018 Woko. All rights reserved.
//

import Foundation

public protocol BinaryCodable {
    func serialize(_ builder:DataBuilder)
    static func deserialize(_ input: DataReader) -> Self?
    
    // convenience methods
    func serialize() -> Data
    static func deserialize(_ data:Data) -> Self?
}

extension BinaryCodable {
    public func serialize() -> Data {
        let builder = DataBuilder()
        serialize(builder)
        return builder.toData()
    }
    
    public static func deserialize(_ data:Data) -> Self? {
        let reader = DataReader(data:data)
        return deserialize(reader)
    }
}
