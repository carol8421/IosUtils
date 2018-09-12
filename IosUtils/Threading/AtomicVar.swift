import Foundation

public final class AtomicVar<T> {
    private var lock: pthread_mutex_t
    private var value: T
    
    public init(_ value: T) {
        self.lock = pthread_mutex_t()
        self.value = value
        
        pthread_mutex_init(&self.lock, nil)
    }
    
    deinit {
        pthread_mutex_destroy(&self.lock)
    }
    
    public func get() -> T {
        pthread_mutex_lock(&self.lock)
        let result = self.value
        pthread_mutex_unlock(&self.lock)
        
        return result
    }
    
    public func set(_ val:T) {
        pthread_mutex_lock(&self.lock)
        self.value = val
        pthread_mutex_unlock(&self.lock)
    }
    
    public func action(_ f: (T) -> Void) {
        pthread_mutex_lock(&self.lock)
        f(self.value)
        pthread_mutex_unlock(&self.lock)
    }
    
    public func with<R>(_ f: (T) -> R) -> R {
        pthread_mutex_lock(&self.lock)
        let result = f(self.value)
        pthread_mutex_unlock(&self.lock)
        
        return result
    }
    
    public func modify(_ f: (T) -> T) {
        pthread_mutex_lock(&self.lock)
        self.value = f(self.value)
        pthread_mutex_unlock(&self.lock)
    }
    
    public func modifyResult(_ f: (T) -> T) -> T {
        pthread_mutex_lock(&self.lock)
        let result = f(self.value)
        self.value = result
        pthread_mutex_unlock(&self.lock)
        
        return result
    }
    
    public func modifyAsync(_ f: @escaping (T) -> T) {
        DispatchQueue.global().async(execute: DispatchWorkItem {
            pthread_mutex_lock(&self.lock)
            self.value = f(self.value)
            pthread_mutex_unlock(&self.lock)
        })
    }
    
    public func swap(_ value: T) -> T {
        pthread_mutex_lock(&self.lock)
        let previous = self.value
        self.value = value
        pthread_mutex_unlock(&self.lock)
        
        return previous
    }
}

extension AtomicVar {
    public func exists<Wrapped>() -> Bool where T == Optional<Wrapped> {
        pthread_mutex_lock(&self.lock)
        let result = self.value != nil
        pthread_mutex_unlock(&self.lock)
        
        return result
    }
}
