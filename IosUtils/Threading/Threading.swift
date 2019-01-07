//
//  AsyncHelper.swift
//  Networkamp
//
//  Created by woko on 30/06/2018.
//  Copyright © 2018 Pandastic Games. All rights reserved.
//

import UIKit

public class Threading {
    static let threadPool = ThreadPool(6)
    
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
    
    static public func After(_ time:Double, _ workload:@escaping ()->Void) {
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + time, execute: workload)
    }
    
    static public func AsyncPool(_ workload:@escaping () -> Void) {
        threadPool.addTask(TPTask(workload:workload))
    }
    
    class TPTask: InterruptibleRunnable {
        func run() {
            workload()
        }
        
        var interrupted = false
        func interrupt() {
            interrupted = true
        }
        
        func isInterrupted() -> Bool {
            return interrupted
        }
        
        var workload:() -> Void
        init(workload:@escaping () -> Void) {
            self.workload = workload
        }
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
