//
//  KeyValSqliteDB.swift
//  Networkamp
//
//  Created by woko on 27/06/2018.
//  Copyright © 2018 Pandastic Games. All rights reserved.
//

public class FileStorage {
    var path:URL?
    let lock = KVLock()
    var size:Int64 = 0
    var infos:[FileInfo] = []
    
    public init() {
        
    }
    
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
                //self.size += size
                return FileInfo(name:$0.lastPathComponent, size: Int64(size), date: Int(date.timeIntervalSince1970))
                }.sorted(by: { (left, right) -> Bool in
                    return left.date < right.date
                })
            size = infos.map { $0.size }.reduce(0,+)
        }
    }
    
    public func GetSize() -> Int64? {
        return size
    }
    
    public func Get(_ key: String) -> Data? {
        guard let path = path else { return nil }
        let final = path.appendingPathComponent(key).path
        
        if let data = readFile(final) {
            return data
        }
        return nil
    }
    
    public func GetPath(_ key: String) -> String? {
        guard let path = path else { return nil }
        let final = path.appendingPathComponent(key).path
        
        let fileManager:FileManager = FileManager.default
        if fileManager.fileExists(atPath: final) {
            return final
        }
        return nil
    }
    
    public func Exists(_ key: String) -> Bool {
        guard let path = path else { return false }
        let final = path.appendingPathComponent(key).path
        
        let fileManager:FileManager = FileManager.default
        return fileManager.fileExists(atPath: final)
    }
    
    func getExtension(_ name:String) -> String {
        let parts = name.components(separatedBy: "/").filter { !$0.isEmpty };
        if parts.count > 0 {
            return parts[parts.count-1]
        }
        return ""
    }
    
    public func Set(_ name:String, val: Data) {
        guard let path = path else { return }
        let final = path.appendingPathComponent(name).path
        
        lock.locked {
            writeFile(final,data:val)
            self.refreshFiles()
        }
    }
    
    public func Set(_ name:String, url: URL) -> URL? {
        guard let path = path else { return nil }
        let final = path.appendingPathComponent(name)
        
        var wasSuccess = false
        lock.locked {
            do {
                try FileManager.default.moveItem(at: url, to: final)
                self.refreshFiles()
                wasSuccess = true
            } catch {
                print(error)
            }
        }
        return wasSuccess ? final : nil
    }
    
    public func Delete(_ key: String) {
        guard let path = path else { return }
        let final = path.appendingPathComponent(key).path
        
        lock.locked {
            let fileManager = FileManager.default
            _ = try? fileManager.removeItem(atPath:final)
            self.refreshFiles()
        }
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
        public var name:String = ""
        public var size:Int64 = 0
        public var date:Int = 0
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
