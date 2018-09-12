//
//  ThreadsafeTimer.swift
//  Networkamp
//
//  Created by woko on 06/07/2018.
//  Copyright © 2018 Pandastic Games. All rights reserved.
//

import Foundation

public class ThreadsafeTimer {
    static public func Later(delay:Double, callback:@escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: callback)
    }
}
