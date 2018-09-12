//
//  DataExtensions.swift
//  IosUtils
//
//  Created by woko on 10/09/2018.
//  Copyright © 2018 Woko. All rights reserved.
//

import Foundation

public extension Data {
    public func appendTo(fileURL: URL) {
        if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else {
            try? write(to: fileURL, options: .atomic)
        }
    }
}
