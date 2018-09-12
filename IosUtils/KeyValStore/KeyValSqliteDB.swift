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
    let table = Table("keyval")
    let keyDb = Expression<String>("key")
    let valDb = Expression<SQLite.Blob>("val")
    let typeDb = Expression<String>("type")
    
    public func Open(_ name: String) {
        let fileManager:FileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let documentUrl = directory.appendingPathComponent(name)
        db = try? Connection(documentUrl.path)
        
        if let db = db {
            _ = try? db.run(table.create { t in
                t.column(keyDb, primaryKey: true)
                t.column(valDb)
                t.column(typeDb)
            })
            _ = try? db.run(table.createIndex(typeDb, ifNotExists: true))
        }
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
                    safePutInCache(key, val: val, size: row[valDb].bytes.count)
                    return val
                }
            }
        } catch { return nil}
        return nil
    }
    
    public func GetAll<T>(type:T.Type) -> [T] where T : KeyValItem {
        guard let db = db else { return [] }
        var res:[T] = []
        
        do {
            for row in try db.prepare(table.select(valDb).filter(typeDb == String(describing: type))) {
                var data = Data()
                data.append(contentsOf: row[valDb].bytes)
                let val = deserialize(data,clazz:type)
                if let val = val {
                    res.append(val)
                }
            }
        } catch { return []}
        
        return res
    }
    
    public func Set<T: KeyValItem>(_ val: T) {
        guard let db = db else { return }
        
        let data = serialize(val)        
        let insert = table.insert(or: .replace, keyDb <- val.pkey, valDb <- data.datatypeValue, typeDb <- String(describing: T.self))
        _ = try? db.run(insert)
        safePutInCache(val.pkey, val: val, size: data.count)
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
