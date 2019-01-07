public class RandomCache<Key: Hashable, Value: Sizeable> {
   
    private let lock = Lock()
    private var capacity: Int // bytes
    private var size: Int = 0
    private var map: [Key:Value] = [:]
    
    public var Capacity:Int {
        return capacity
    }
    
    public var Size:Int {
        return size
    }
    
    public init(capacity: Int) {
        self.capacity = capacity
    }
    
    public func Clear() {
        lock.locked {
            self.map = [:]
            self.size = 0
        }
    }
    
    public func GetAll(_ callback:(Value)->Bool) -> [Value] {
        var res:[Value] = []
        lock.locked {
            res = map.values.filter { callback($0) }
        }
        return res
    }
    
    public func Get(_ key:Key) -> Value? {
        var res:Value?
        lock.locked {
            if let node = map[key] {
                res = node
            }
        }
        return res
    }
    
    public func Set(_ key:Key, _ value:Value) {
        lock.locked {
            if let item = map[key] {
                size -= item.getSize()
                map[key] = value
                size += value.getSize()
            } else {
                map[key] = value
                size += value.getSize()
                
                // Truncate from the tail
                while size > capacity && map.count > 0 {
                    if let first = map.first {
                        map.removeValue(forKey: first.key)
                        size -= first.value.getSize()
                    } else {
                        break
                    }
                }
            }
        }
    }
    
    public func Delete(_ key:Key) {
        lock.locked {
            if let item = map[key] {
                size -= item.getSize()
            }
            map.removeValue(forKey: key)
        }
    }
}
