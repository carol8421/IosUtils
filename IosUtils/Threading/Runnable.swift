//
//  Runnable.swift
//  Networkamp
//
//  Created by woko on 30/06/2018.
//  Copyright © 2018 Pandastic Games. All rights reserved.
//

import UIKit

@objc public protocol Runnable {
    func run()
}

@objc public protocol Interruptible {
    func interrupt()
    func isInterrupted() -> Bool
}

@objc public protocol InterruptibleRunnable : Runnable, Interruptible {

}

open class InterruptError: Error {
}

open class AbstractInterruptibleRunnable: InterruptibleRunnable {
    
    public init() {
        
    }
    
    // allow compositioning of interrupts - register child runnables and automatically interrupt them
    var interrupted = false
    var inner = WeakRefStore<Interruptible>()
    
    open func addInner(_ inner:Interruptible) {
        self.inner.AddIfNotExists(inner)
    }
    
    open func interrupt() {
        interrupted = true
        for item in inner.Get() {
            item.interrupt()
        }
    }
    
    open func checkInterrupted() throws {
        if interrupted {
            throw InterruptError()
        }
    }
    
    open func isInterrupted() -> Bool {
        return interrupted
    }
    
    let semaphore = DispatchSemaphore(value:0)
    
    // Async wait - stop execution of the thread via `try wait()` or `waitWasInterrupted()` until `finished()` has been called, typically from a callback.
    // The `task` method encapsulates a callback and after execution calls `finishes()` automatically, e.g.
    // obj.method(task({
    //    data in
    //    do_stuff()
    // }))
    // try wait()
    open func task<T>(_ callback: @escaping (T) -> Void) -> ((T) -> Void) {
        let closure: (T) -> Void = {
            t in
            callback(t)
            self.finished()
        }
        return closure
    }
    
    open func finished() {
        semaphore.signal()
    }
    
    open func waitWasInterrupted() -> Bool {
        while true {
            if semaphore.wait(timeout: DispatchTime.now() + .seconds(1)) == .timedOut {
                if isInterrupted() {
                    return true
                }
            } else {
                break
            }
        }
        return isInterrupted()
    }
    
    open func raise() throws {
        throw InterruptError()
    }
    
    open func waitTimeout(_ time:Double) throws {
        let start = DispatchTime.now()
        while true {
            if semaphore.wait(timeout: DispatchTime.now() + .seconds(1)) == .timedOut {
                if isInterrupted() {
                    throw InterruptError()
                }
            } else {
                break
            }
            if Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1000000000.0 >= time {
                //print("TIMEOUT ELAPSED")
                throw InterruptError()
            }
        }
        if isInterrupted() {
            throw InterruptError()
        }
    }
    
    open func wait() throws {
        while true {
            if semaphore.wait(timeout: DispatchTime.now() + .seconds(1)) == .timedOut {
                if isInterrupted() {
                    throw InterruptError()
                }
            } else {
                break
            }
        }
        if isInterrupted() {
            throw InterruptError()
        }
    }
    
    open func run() {
        do {
            try doWork()
        } catch let _ as InterruptError {
            // run was interrupted
        } catch {
            // shouldn't happen
        }
    }
    
    open func doWork() throws {
        
    }
}

open class AsyncTask: AbstractInterruptibleRunnable {
    var doWork: () -> ()
    init(doWork: @escaping () -> ()) {
        self.doWork = doWork
    }
    
    override open func run() {
        if !isInterrupted() {
            doWork()
        }
    }
}

open class SyncTask: AbstractInterruptibleRunnable {
    var doWork: (SyncTask) -> ()
    
    public init(doWork: @escaping (SyncTask) -> ()) {
        self.doWork = doWork
    }
    
    
    override open func run() {
        if !isInterrupted() {
            doWork(self)
            
            _ = waitWasInterrupted()
            
        }
    }
}

open class UiRelatedTask<Result>: AbstractInterruptibleRunnable {
    var doWork: () -> Result
    var thenOnMain: (Result) -> ()
    
    init(doWork: @escaping () -> Result, thenOnMain: @escaping (Result) -> ()) {
        self.doWork = doWork
        self.thenOnMain = thenOnMain
    }
    
    override open func run() {
        if !isInterrupted() {
            let res = doWork()
            if (!isInterrupted()) {
                DispatchQueue.main.async {
                    self.thenOnMain(res)
                }
            }
        }
    }
}
