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

fileprivate class CacheEntry: Sizeable {
    var obj:KeyValItem
    var size = 0
    var type:String
    
    init(obj:KeyValItem, size:Int, type:String) {
        self.obj = obj
        self.size = size
        self.type = type
    }
    
    func getSize() -> Int {
        return size
    }
}

fileprivate class CacheAllEntry: Sizeable {
    var objs:[KeyValItem]
    var size = 0
    
    init(objs:[KeyValItem], size:Int) {
        self.objs = objs
        self.size = size
    }
    
    func getSize() -> Int {
        return size
    }
}


public class KeyValCacheBase {
    let GET_ALL_CACHE_RATE:Float = 0.3
    fileprivate var cache: RandomCache<String,CacheEntry>?
    fileprivate var allCache: RandomCache<String,CacheAllEntry>?
    var excludeCache: [String:Bool]?
    
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
    
    public func UseCache(_ size:Int, excludeKeys: [String]? = nil) {
        cache = RandomCache<String,CacheEntry>(capacity:size)
        allCache = RandomCache<String,CacheAllEntry>(capacity:Int(Float(size) * GET_ALL_CACHE_RATE))
        if let excludeKeys = excludeKeys {
            self.excludeCache = [:]
            excludeKeys.forEach {
                self.excludeCache?[$0] = true
            }
        }
    }
    
    func getFromCache<T: KeyValItem>(_ key:String, clazz:T.Type) -> T? {
        guard let cache = cache else { return nil }
        if let item = cache.Get(key) {
            if let obj = item.obj as? T {
                return obj
            }
        }
        return nil
    }
    
    func getAllFromCache<T: KeyValItem>(_ clazz:T.Type) -> [T]? {
        guard let allCache = allCache else { return [] }
        
        let type = String(describing: clazz)
        if let item = allCache.Get(type), let res = item.objs as? [T] {
            return res
        }
        return nil
    }
    
    func putAllInCache<T: KeyValItem>(_ vals:[KeyValItem], clazz:T.Type, size:Int) {
        guard let allCache = allCache else { return }
        
        let type = String(describing: clazz)
        allCache.Set(type, CacheAllEntry(objs:vals,size:size))
    }
    
    /*func putInCache<T: KeyValItem>(_ key:String, val:T, size:Int, type:T.Type) {
        guard let cache = cache else { return }
        if excludeCache != nil && excludeCache!.contains(key) { return }
        
        cache.Set(key, CacheEntry(obj:val,size:size,type:String(describing: type)))
        if let allCache = allCache {
            allCache.Delete(String(describing: type))
        }
    }*/
    
    func safePutInCache<T: KeyValItem>(_ key:String, val:T, size:Int, type: T.Type) {
        guard let cache = cache else { return }
        if let excludeCache = excludeCache, excludeCache[key] != nil { return }
        //if cache.Get(key) != nil { return }
        
        cache.Set(key, CacheEntry(obj:val,size:size,type:String(describing: type)))
        if let allCache = allCache {
            allCache.Delete(String(describing: type))
        }
    }
    
    func removeFromCache(_ key:String) {
        guard let cache = cache else { return }
        
        if let allCache = allCache, let val = cache.Get(key) {
            allCache.Delete(val.type)
        }
        cache.Delete(key)
    }
    
    func clearCache() {
        if let cache = cache {
            cache.Clear()
        }
    }
}
