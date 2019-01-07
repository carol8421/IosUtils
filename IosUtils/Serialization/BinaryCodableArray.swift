//
//  BinaryCodableArray.swift
//  IosUtils
//
//  Created by woko on 01/10/2018.
//  Copyright © 2018 Woko. All rights reserved.
//

import Foundation

final public class BinaryCodableArray<T: BinaryCodable>: BinaryCodable {
    
    var items:[T] = []
    
    public init(_ items:[T]) {
        self.items = items
    }
    
    public func serialize(_ builder:DataBuilder) {
        builder.appendInt(items.count)
        for item in items {
            item.serialize(builder)
        }
    }
    
    public static func deserialize(_ input: DataReader) -> BinaryCodableArray<T>? {
        do {
            let res = BinaryCodableArray<T>([])
            let amount = try input.readInt()
            for _ in 0..<amount {
                if let item = T.deserialize(input) {
                    res.items.append(item)
                }
            }
            return res
        } catch {
            return nil
        }
    }
    
    public func getItems() -> [T] {
        return items
    }
    
}
