//
//  Extensions.swift
//  IosUtils
//
//  Created by woko on 01/10/2018.
//  Copyright © 2018 Woko. All rights reserved.
//

import Foundation

extension String: BinaryCodable {
    public func serialize(_ builder:DataBuilder) {
        builder.appendString(self)
    }
    
    public static func deserialize(_ input: DataReader) -> String? {
        do {
            return try input.readString()
        } catch {
            return nil
        }
    }
}
