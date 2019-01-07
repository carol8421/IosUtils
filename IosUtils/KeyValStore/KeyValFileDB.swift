//
//  KeyValSqliteDB.swift
//  Networkamp
//
//  Created by woko on 27/06/2018.
//  Copyright © 2018 Pandastic Games. All rights reserved.
//

public class KeyValFileDB: KeyValCacheBase, KeyValDB {
    var path:URL?
    let lock = KVLock()
    var size = 0
    var infos:[FileInfo] = []
    
    public func Open(_ name: String) {
        let fileManager:FileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        path = directory.appendingPathComponent(name)
        
        if let path = path {
            let fileManager = FileManager.default
            _ = try? fileManager.createDirectory(atPath:path.path,withIntermediateDirectories:true)
        }
        refreshFiles()
    }
    
    func refreshFiles() {
        guard let path = path else { return }
        
        let fileManager:FileManager = FileManager.default
        if let files = try? fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]) {
            infos = files.map {
                let date = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                let size = (try? $0.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                self.size += size
                return FileInfo(name:$0.lastPathComponent, size: size, date: Int(date.timeIntervalSince1970))
                }.sorted(by: { (left, right) -> Bool in
                    return left.date < right.date
                })
            size = infos.map { $0.size }.reduce(0,+)
        }
    }
    
    
    public func Close() {
        
    }
    
    public func Get<T>(_ key: String, type: T.Type) -> T? where T : KeyValItem {
        guard let path = path else { return nil }
        let final = path.appendingPathComponent(key+"."+String(describing: type)).path
        if let tmp = getFromCache(key, clazz: type) { return tmp }
        
        if let data = readFile(final) {
            let val = deserialize(data,clazz:type)
            if let val = val {
                safePutInCache(key, val: val, size: data.count, type: type)
                return val
            }
        }
        return nil
    }
    
    func getExtension(_ name:String) -> String {
        let parts = name.components(separatedBy: "/").filter { !$0.isEmpty };
        if parts.count > 0 {
            return parts[parts.count-1]
        }
        return ""
    }
    
    public func GetAll<T>(type:T.Type) -> [T] where T : KeyValItem {
        guard let path = path else { return [] }
        var res:[T] = []
        
        let typeString = String(describing: T.self)
        
        let fileManager:FileManager = FileManager.default
        if let files = try? fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: nil) {
            for file in files {
                if getExtension(file.path) == typeString {
                    if let tmp = getFromCache(file.lastPathComponent, clazz: type) {
                        res.append(tmp)
                    } else if let data = readFile(file.path), let val = deserialize(data,clazz:type) {
                        res.append(val)
                    }
                }
            }
        }
        
        return res
    }
    
    public func Set<T: KeyValItem>(_ val: T) {
        guard let path = path else { return }
        let final = path.appendingPathComponent(val.pkey+"."+String(describing: T.self)).path
        
        let data = serialize(val)
        lock.locked {
            writeFile(final,data:data)
            safePutInCache(val.pkey, val: val, size: data.count, type: T.self)
            self.refreshFiles()
        }
    }
    
    public func DeleteOldest() {
        if infos.count > 0 {
            Delete(infos[0].name)
        }
    }
    
    public func Delete(_ key: String) {
        guard let path = path else { return }
        let final = path.appendingPathComponent(key).path
        
        lock.locked {
            removeFromCache(key)
            let fileManager = FileManager.default
            _ = try? fileManager.removeItem(atPath:final)
            self.refreshFiles()
        }
    }
    
    public func DeleteAll() {
        // TODO implement
    }
    
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
    
    public func GetMeta(_ name:String) -> FileInfo? {
        return infos.filter { $0.name == name }.first
    }
    
    public func GetMeta() -> [FileInfo] {
        return infos
    }
    
    public struct FileInfo {
        var name:String = ""
        var size:Int = 0
        var date:Int = 0
    }
    
    class KVLock {
        private var mutex = pthread_mutex_t()
        
        public init() {
            pthread_mutex_init(&self.mutex, nil)
        }
        
        deinit {
            pthread_mutex_destroy(&self.mutex)
        }
        
        public func locked(_ f: () -> ()) {
            pthread_mutex_lock(&self.mutex)
            f()
            pthread_mutex_unlock(&self.mutex)
        }
    }
}
