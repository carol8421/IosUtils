import Foundation

//https://github.com/peter-iakovlev/Signals/tree/master/SwiftSignalKit
public final class ThreadPoolTask {
    public var action: InterruptibleRunnable
    
    public init(_ action: InterruptibleRunnable) {
        self.action = action
    }
    
    func execute() {
        if !action.isInterrupted() {
            action.run()
        }
    }
    
    public func interrupt() {
        action.interrupt()
    }
}

public func ==(lhs: ThreadPoolTask, rhs: ThreadPoolTask) -> Bool {
    return lhs === rhs
}

open class ThreadPoolTaskRunner: AbstractInterruptibleRunnable {
    var method:() -> Void
    
    public init(method:@escaping () -> Void) {
        self.method = method
    }
    
    override open func doWork() throws {
        method()
    }
}

@objc public final class ThreadPool: NSObject {
    private var threadCount = 1
    private var threads: [Thread] = []
    private var queue:[ThreadPoolTask] = []
    private var runningTasks: [ThreadPoolTask] = []
    private var mutex: pthread_mutex_t
    private var threadsMutex: pthread_mutex_t
    private var condition: pthread_cond_t
    private var sumTasks = 0
    private var queuedTasks = 0
    public var shutdownThreads = false
    private var isStopped = false
    private var workerLock = Lock()
    static let CLOSE_TIMEOUT:Double = 60.0
    
    public func locked(_ f: () -> ()) {
        workerLock.locked(f)
    }
    
    public func getRunningTasks() -> [ThreadPoolTask] {
        return self.runningTasks
    }
    
    public func getQueuedTasks() -> Int {
        return queuedTasks
    }
    
    public func getProgressTasks() -> Int {
        return sumTasks - queuedTasks
    }
    
    public func getSumTasks() -> Int {
        return sumTasks
    }
    
    @objc class func threadEntryPoint(_ threadPool: ThreadPool) {
        var lastAction = Date().timeIntervalSince1970
        while (true) {
            var task: ThreadPoolTask!
            
            pthread_mutex_lock(&threadPool.threadsMutex)
            
            while (true)
            {
                if (Date().timeIntervalSince1970 - lastAction) > ThreadPool.CLOSE_TIMEOUT {
                    //print("killing thread")
                    pthread_mutex_lock(&threadPool.mutex)
                    threadPool.threads.remove(element: Thread.current)
                    pthread_mutex_unlock(&threadPool.mutex)
                    
                    pthread_mutex_unlock(&threadPool.threadsMutex)
                    return
                }
                if threadPool.shutdownThreads {
                    pthread_mutex_unlock(&threadPool.threadsMutex)
                    return
                }
                if threadPool.queue.count == 0 { //while threadPool.queue.count == 0 {
                    //pthread_cond_wait(&threadPool.condition, &threadPool.threadsMutex);
                    var time_to_wait = timespec(tv_sec:60,tv_nsec:0)
                    pthread_cond_timedwait_relative_np(&threadPool.condition, &threadPool.threadsMutex, &time_to_wait)
                }
                
                pthread_mutex_lock(&threadPool.mutex)
                if threadPool.queue.count != 0 {
                    task = threadPool.queue[0]
                }
                
                if task != nil {
                    threadPool.queue = threadPool.queue.filter{ $0 !== task }
                    
                    pthread_mutex_unlock(&threadPool.mutex)
                    /*if let index = threadPool.queue.index(of: task) {
                        threadPool.queue.remove(at: index)
                    }*/
                    
                    break
                } else {
                    pthread_mutex_unlock(&threadPool.mutex)
                }
            }
            if task != nil {
                pthread_mutex_lock(&threadPool.mutex)
                threadPool.runningTasks.append(task)
                pthread_mutex_unlock(&threadPool.mutex)
            }
            pthread_mutex_unlock(&threadPool.threadsMutex);
            
            if task != nil {
                autoreleasepool {
                    task.execute()
                }
                pthread_mutex_lock(&threadPool.mutex);
                threadPool.runningTasks = threadPool.runningTasks.filter{ $0 !== task }
                threadPool.queuedTasks -= 1
                lastAction = Date().timeIntervalSince1970
                pthread_mutex_unlock(&threadPool.mutex);
                //pthread_cond_broadcast(&threadPool.condition)
            }
        }
    }
    
    public init(_ threadCount: Int, threadPriority: Double = 0.0) {
        assert(threadCount > 0, "threadCount < 0")
        
        self.threadCount = threadCount
        self.mutex = pthread_mutex_t()
        self.threadsMutex = pthread_mutex_t()
        self.condition = pthread_cond_t()
        pthread_mutex_init(&self.mutex, nil)
        pthread_mutex_init(&self.threadsMutex, nil)
        pthread_cond_init(&self.condition, nil)
        
        super.init()
        
        /*for _ in 0 ..< threadCount {
            let thread = Thread(target: ThreadPool.self, selector: #selector(ThreadPool.threadEntryPoint(_:)), object: self)
            thread.threadPriority = threadPriority
            self.threads.append(thread)
            thread.start()
        }*/
    }
    
    deinit {
        pthread_mutex_destroy(&self.mutex)
        pthread_mutex_destroy(&self.threadsMutex)
        pthread_cond_destroy(&self.condition)
    }
    
    func checkThreads() {
        guard self.threads.count < threadCount else { return }
        let newThreads = min(threadCount - self.threads.count,self.queue.count)
        for _ in 0..<newThreads{
            let thread = Thread(target: ThreadPool.self, selector: #selector(ThreadPool.threadEntryPoint(_:)), object: self)
            //thread.threadPriority = threadPriority
            self.threads.append(thread)
            thread.start()
        }
    }
    
    public func addTask(_ task: ThreadPoolTask) {
        pthread_mutex_lock(&self.mutex)
        
        if !isStopped {
            self.queue.append(task)
            sumTasks += 1
            queuedTasks += 1
            
            checkThreads()
        }
        
        pthread_cond_broadcast(&self.condition)
        pthread_mutex_unlock(&self.mutex)
    }
    
    public func addTask(_ runnable: InterruptibleRunnable) {
        addTask(ThreadPoolTask(runnable))
    }
    
    public func executeAndShutdown() {
        while !execute() {
            // execute until donw
        }
        shutdown()
    }
    
    public func execute(_ sleep:Int = 100000) -> Bool {
        var hasFinished = false
        pthread_mutex_lock(&self.mutex)
        if self.queue.count <= 0 && self.runningTasks.count <= 0 {
            hasFinished = true
        }
        pthread_mutex_unlock(&self.mutex)
        if (hasFinished) {
            return true
        }
        
        usleep(UInt32(sleep))
        return false
    }
    
    public func shutdown() {
        DispatchQueue.global().async(execute: DispatchWorkItem {
            while true {
                pthread_mutex_lock(&self.mutex)
                if self.queue.count <= 0 && self.runningTasks.count <= 0 {
                    self.shutdownThreads = true
                }
                pthread_mutex_unlock(&self.mutex)
                if self.shutdownThreads {
                    break
                }
            }
            pthread_cond_broadcast(&self.condition)
        })
    }
    
    public func doOnQueue(_ callback:@escaping ([ThreadPoolTask]) -> [ThreadPoolTask]) {
        pthread_mutex_lock(&self.mutex)
        
        let startQueue = queue.count
        
        self.queue = callback(self.queue)
        
        let diffQueue = queue.count - startQueue
        sumTasks += diffQueue
        queuedTasks += diffQueue
        
        checkThreads()
        
        pthread_mutex_unlock(&self.mutex)
    }
    
    public func doWithRunningTasks(_ callback:@escaping ([ThreadPoolTask]) -> Void) {
        pthread_mutex_lock(&self.mutex)
        
        callback(self.runningTasks)
        
        pthread_mutex_unlock(&self.mutex)
    }
    
    public func doOnQueueWithRunningTasks(_ callback:@escaping ([ThreadPoolTask], [ThreadPoolTask]) -> [ThreadPoolTask]) {
        pthread_mutex_lock(&self.mutex)
        
        let startQueue = queue.count
        
        self.queue = callback(self.queue,self.runningTasks)
        
        let diffQueue = queue.count - startQueue
        sumTasks += diffQueue
        queuedTasks += diffQueue
        
        checkThreads()
        
        pthread_mutex_unlock(&self.mutex)
    }
    
    public func stop() {
        pthread_mutex_lock(&self.mutex)
        
        self.queue.removeAll()
        for item in self.runningTasks {
            item.interrupt()
        }
        isStopped = true
        pthread_mutex_unlock(&self.mutex)
    }
    
    
    public func isCurrentThreadInPool() -> Bool {
        let currentThread = Thread.current
        for thread in self.threads {
            if currentThread.isEqual(thread) {
                return true
            }
        }
        return false
    }
}
