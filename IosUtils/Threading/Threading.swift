//
//  AsyncHelper.swift
//  Networkamp
//
//  Created by woko on 30/06/2018.
//  Copyright © 2018 Pandastic Games. All rights reserved.
//

import UIKit

public class Threading {
    static public func AsyncUI<T>(_ workload:@escaping () -> T?, callback:@escaping (_ result: T?) -> Void) {
        DispatchQueue.global().async(execute: DispatchWorkItem {
            let res = workload()
            DispatchQueue.main.async {
                callback(res)
            }
        })
    }
    
    static public func Async(_ workload:@escaping () -> Void) {
        DispatchQueue.global().async(execute: DispatchWorkItem {
            workload()
        })
    }
    
    static public func Main(_ workload:@escaping () -> Void) {
        DispatchQueue.main.async {
            workload()
        }
    }
    
    static public func SyncMain(_ workload:@escaping () -> Void) {
        if Thread.isMainThread {
            workload()
        } else {
            DispatchQueue.main.sync {
                workload()
            }
        }
    }
}
