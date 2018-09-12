import UIKit
import Foundation

public protocol KeyValDB {
    func Open(_ name:String)
    func Close()
    func Get<T: KeyValItem>(_ key:String, type:T.Type) -> T?
    func GetAll<T: KeyValItem>(type:T.Type) -> [T]
    func Set<T: KeyValItem>(_ val:T)
    func Delete(_ key:String)
    func DeleteAll()
}

public protocol KeyValItem: Codable {
    var pkey: String { get }
}

private class CacheEntry: Sizeable {
    var obj:KeyValItem
    var size = 0
    
    init(obj:KeyValItem, size:Int) {
        self.obj = obj
        self.size = size
    }
    
    func getSize() -> Int {
        return size
    }
}


public class KeyValCacheBase {
    fileprivate var cache: LRUCache<String,CacheEntry>?
    var excludeCache: [String]?
    
    public init() {
        
    }
    
    func deserialize<T: KeyValItem>(_ data:Data, clazz:T.Type) -> T? {
        return try? JSONDecoder().decode(clazz, from: data)
    }
    
    func serialize<T: KeyValItem>(_ item:T) -> Data {
        let val = try? JSONEncoder().encode(item);
        if let val = val {
            return val
        }
        return Data()
    }
    
    public func UseCache(_ size:Int, excludeKeys: [String]) {
        self.UseCache(size)
        self.excludeCache = excludeKeys
    }
    
    public func UseCache(_ size:Int) {
        cache = LRUCache<String,CacheEntry>(capacity:size)
    }
    
    func getFromCache<T: KeyValItem>(_ key:String, clazz:T.Type) -> T? {
        guard let cache = cache else { return nil }
        let item = cache[key]
        if let item = item {
            if let obj = item.obj as? T {
                return obj
            }
        }
        return nil
    }
    
    func putInCache(_ key:String, val:KeyValItem, size:Int) {
        guard let cache = cache else { return }
        if excludeCache != nil && excludeCache!.contains(key) { return }
        
        cache[key] = CacheEntry(obj:val,size:size)
    }
    
    func safePutInCache(_ key:String, val:KeyValItem, size:Int) {
        guard let cache = cache else { return }
        if excludeCache != nil && excludeCache!.contains(key) { return }
        if cache[key] != nil { return }
        
        cache[key] = CacheEntry(obj:val,size:size)
    }
   
    func removeFromCache(_ key:String) {
        guard let cache = cache else { return }
        cache[key] = nil
    }
    
    func clearCache() {
        if let cache = cache {
            UseCache(cache.Capacity)
        }
    }
}
