private class LRUCacheNode<Key: Hashable, Value> {
    let key: Key
    var value: Value
    var previous: LRUCacheNode?
    var next: LRUCacheNode?
    
    init(key: Key, value: Value) {
        self.key = key
        self.value = value
    }
}

public protocol Sizeable {
    func getSize() -> Int
}

extension Data: Sizeable {
    public func getSize() -> Int {
        return self.count
    }
}

public class LRUCache<Key: Hashable, Value: Sizeable> {
    private typealias Node = LRUCacheNode<Key, Value>
    
    private let lock = Lock()
    private var capacity: Int // bytes
    private var size: Int = 0
    private var queue: [Node] = []
    
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
            self.queue = []
            self.size = 0
        }
    }
    
    public func GetAll(_ callback:(Value)->Bool) -> [Value] {
        var res:[Value] = []
        lock.locked {
            res = queue.filter { callback($0.value) }.map { $0.value }
        }
        return res
    }
    
    public subscript (key: Key) -> Value? {
        get {
            var res:Value?
            lock.locked {
                if let node = findNode(key) {
                    moveNodeToFront(node)
                    res = node.value
                }
            }
            return res
        }
        set(newValue) {
            lock.locked {
                if let value = newValue {
                    // Value was provided. Find the corresponding node, update its value, and move
                    // it to the front of the list. If it's not found, create it at the front.
                    if let node = findNode(key) {
                        size -= node.value.getSize()
                        node.value = value
                        size += value.getSize()
                        moveNodeToFront(node)
                    } else {
                        let newNode = Node(key: key, value: value)
                        addNodeToFront(newNode)
                        
                        // Truncate from the tail
                        while size > capacity && queue.count > 0 {
                            let item = queue[queue.count-1]
                            queue.remove(at: queue.count-1)
                            size -= item.value.getSize()
                           //print("remove from tail: size",size)
                        }
                    }
                } else {
                    if let node = findNode(key) {
                        removeNode(node)
                        size -= node.value.getSize()
                    }
                }
            }
        }
    }
    
    
    
    // MARK: -
    
    private func addNodeToFront(_ node: Node) {
        queue.insert(node, at: 0)
        size += node.value.getSize()
        //print("addNodeToFront: new size",size,"of",capacity)
    }
    
    private func moveNodeToFront(_ node: Node) {
        removeNode(node)
        addNodeToFront(node)
    }
    
    private func findNode(_ key: Key) -> Node? {
        return queue.first(where: { $0.key == key })
    }
    
    private func removeNode(_ node: Node) {
        if let index = queue.index(where: { $0.key == node.key }) {
            queue.remove(at: index)
        }
    }
}
