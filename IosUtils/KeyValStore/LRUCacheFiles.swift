private class LRUFileCacheNode {
    let key: String
    var size:Int
    var previous: LRUFileCacheNode?
    var next: LRUFileCacheNode?
    
    init(key: String, size:Int) {
        self.key = key
        self.size = size
    }
}

public protocol BinarySizeable: Sizeable {
    func getData() -> Data
    static func initFromData(data:Data) -> BinarySizeable
}

extension Data: BinarySizeable {
    public func getData() -> Data {
        return self
    }
    
    public static func initFromData(data: Data) -> BinarySizeable {
        return data
    }
}


public class LRUCacheFiles {
    private typealias Node = LRUFileCacheNode
    
    private var path:URL?
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
    
    public init(name:String,capacity: Int) {
        let fileManager:FileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        path = directory.appendingPathComponent(name)        
        if let path = path {
            let fileManager = FileManager.default
            _ = try? fileManager.createDirectory(atPath:path.path,withIntermediateDirectories:true)
        }
        
        self.capacity = capacity
        loadFiles()
        //deleteFiles()
    }
    
    func loadFiles() {
        guard let path = path else { return }
        
        let fileManager:FileManager = FileManager.default
        if let files = try? fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                let fileSize = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                if fileSize > 0 {
                    let newNode = Node(key: file.lastPathComponent, size: fileSize)
                    addNodeToFront(newNode)
                    size += newNode.size
                }
            }
        }
    }
    
    /*func deleteFiles() {
        guard let path = path else { return }
        
        let fileManager:FileManager = FileManager.default
        if let files = try? fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]) {
            files.forEach { _ = try? fileManager.removeItem(at: $0) }
        }
    }*/
    
    func writeFile(_ path:String, data:Data) {
        let data2 = data as NSData
        data2.write(toFile: path, atomically: true)
    }
    
    func readFile(_ path:String) -> Data? {
        if let data = NSData(contentsOfFile: path) {
            return data as Data
        }
        return nil
    }
    
    func getNode(_ key:String) -> Data? {
        guard let path = path else { return nil }
        let final = path.appendingPathComponent(key).path
        
        if let data = readFile(final) {
            return data
        }
        return nil
    }
    
    func setNode(_ key:String, val:Data) {
        guard let path = path else { return }
        let final = path.appendingPathComponent(key).path
        
        writeFile(final,data:val)
    }
    
    func setNode(_ key:String, url:URL) -> Bool {
        guard let path = path else { return false }
        let final = path.appendingPathComponent(key)
        
        var wasSuccess = false
        do {
            try FileManager.default.moveItem(at: url, to: final)
            wasSuccess = true
        } catch {
            print(error)
        }
        return wasSuccess
    }
    
    func deleteNode(_ key:String) {
        guard let path = path else { return }
        let final = path.appendingPathComponent(key).path
        
        let fileManager:FileManager = FileManager.default
        _ = try? fileManager.removeItem(atPath: final)
    }
    
    public func hasKey(_ key:String) -> Bool {
        return findNode(key) != nil
    }
    
    public func Get(_ key: String) -> Data? {
        var res:Data?
        lock.locked {
            if let node = findNode(key) {
                moveNodeToFront(node)
                res = getNode(node.key)
                if res == nil {
                    removeNode(node)
                    size -= node.size
                }
            }
        }
        return res
    }
    
    public func Remove(_ key:String) {
        lock.locked {
            if let node = findNode(key) {
                deleteNode(key)
                removeNode(node)
                size -= node.size
            }
        }
    }
    
    public func Set(_ key:String, value: Data) {
        lock.locked {
            // Value was provided. Find the corresponding node, update its value, and move
            // it to the front of the list. If it's not found, create it at the front.
            if let node = findNode(key) {
                deleteNode(key)
                removeNode(node)
            }
            let newNode = Node(key: key, size: value.count)
            addNodeToFront(newNode)
            setNode(key, val:value)
            size += newNode.size
            
            // Truncate from the tail
            while size > capacity && queue.count > 0 {
                let item = queue[queue.count-1]
                queue.remove(at: queue.count-1)
                size -= item.size
                deleteNode(item.key)
            }
        }
    }
    
    public func Set(_ key:String, url: URL) {
        lock.locked {
            // Value was provided. Find the corresponding node, update its value, and move
            // it to the front of the list. If it's not found, create it at the front.
            if let node = findNode(key) {
                deleteNode(key)
                removeNode(node)
            }
            let newNode = Node(key: key, size: url.fileSize)
            if setNode(key, url:url) {
                addNodeToFront(newNode)
                size += newNode.size
                
                // Truncate from the tail
                while size > capacity && queue.count > 0 {
                    let item = queue[queue.count-1]
                    queue.remove(at: queue.count-1)
                    size -= item.size
                    deleteNode(item.key)
                }
            }
        }
    }
    
    // MARK: -
    
    private func addNodeToFront(_ node: Node) {
        queue.insert(node, at: 0)
    }
    
    private func moveNodeToFront(_ node: Node) {
        removeNode(node)
        addNodeToFront(node)
    }
    
    private func findNode(_ key: String) -> Node? {
        return queue.first(where: { $0.key == key })
    }
    
    private func removeNode(_ node: Node) {
        if let index = queue.index(where: { $0.key == node.key }) {
            queue.remove(at: index)
        }
    }
}
