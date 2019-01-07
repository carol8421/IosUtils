//
//  KeyValSqliteDB.swift
//  Networkamp
//
//  Created by woko on 27/06/2018.
//  Copyright © 2018 Pandastic Games. All rights reserved.
//

import SQLite

public class KeyValSqliteDB: KeyValCacheBase, KeyValDB {
    var db:Connection?
    var name:String?
    let table = Table("keyval")
    let keyDb = Expression<String>("key")
    let valDb = Expression<SQLite.Blob>("val")
    let typeDb = Expression<String>("type")
    var isPrecached = false
    
    public func BackUp() -> Data? {
        var res:Data?
        if let name = name {
            let fileManager:FileManager = FileManager.default
            let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let documentUrl = directory.appendingPathComponent(name)
            res = documentUrl.readFile()
        }
        return res
    }
    
    public func Open(_ name: String) {
        let fileManager:FileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let documentUrl = directory.appendingPathComponent(name)
        db = try? Connection(documentUrl.path)
        self.name = name
        
        if let db = db {
            _ = try? db.run(table.create { t in
                t.column(keyDb, primaryKey: true)
                t.column(valDb)
                t.column(typeDb)
            })
            _ = try? db.run(table.createIndex(typeDb, ifNotExists: true))
        }
    }
    
    func swiftClassFromString(_ className: String) -> AnyClass! {
        if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String? {
            let fAppName = appName.replacingOccurrences(of: " ", with: "_", options: .literal, range: nil)
            return NSClassFromString("\(fAppName).\(className)")
        }
        return nil;
    }
    
    public func Close() {
        
    }
    
    public func Get<T>(_ key: String, type: T.Type) -> T? where T : KeyValItem {
        guard let db = db else { return nil }
        let tmp = self.getFromCache(key, clazz: type)
        if let tmp = tmp { return tmp }
        
        do {
            for row in try db.prepare(table.select(valDb).filter(keyDb == key && typeDb == String(describing: type))) {
                var data = Data()
                data.append(contentsOf: row[valDb].bytes)
                let val = deserialize(data,clazz:type)
                if let val = val {
                    safePutInCache(key, val: val, size: row[valDb].bytes.count, type:type)
                    return val
                }
            }
        } catch { return nil}
        return nil
    }
    
    public func GetAll<T>(type:T.Type) -> [T] where T : KeyValItem {
        guard let db = db else { return [] }
        if let tmp = getAllFromCache(type), tmp.count > 0 {
            return tmp
        }
        
        var res:[T] = []
        var size = 0
        do {
            for row in try db.prepare(table.select(valDb).filter(typeDb == String(describing: type))) {
                var data = Data()
                data.append(contentsOf: row[valDb].bytes)
                let val = deserialize(data,clazz:type)
                if let val = val {
                    res.append(val)
                    size += data.count
                }
            }
        } catch { return []}
        
        putAllInCache(res, clazz: type, size: size)
        
        return res
    }
    
    public func DumpAll() {
        guard let db = db else { return }
        do {
            for row in try db.prepare(table.select(keyDb,valDb,typeDb)) {
                var data = Data()
                data.append(contentsOf: row[valDb].bytes)
                if let val = String(data:data,encoding:.utf8) {
                    print(row[keyDb],row[typeDb],val)
                }
            }
        } catch { }
    }
    
    public func Set<T: KeyValItem>(_ val: T) {
        guard let db = db else { return }
        
        let data = serialize(val)        
        let insert = table.insert(or: .replace, keyDb <- val.pkey, valDb <- data.datatypeValue, typeDb <- String(describing: T.self))
        _ = try? db.run(insert)
        safePutInCache(val.pkey, val: val, size: data.count, type:T.self)
    }
    
    public func Delete(_ key: String) {
        guard let db = db else { return }
        
        removeFromCache(key)
        let query = table.filter(keyDb == key)
        _ = try? db.run(query.delete())
    }
    
    public func DeleteAll() {
        guard let db = db else { return }
        
        do {
            try db.run(table.delete())
        } catch { }
        clearCache()
    }
}
