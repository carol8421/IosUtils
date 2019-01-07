//
//  KeyValSqliteDB.swift
//  Networkamp
//
//  Created by woko on 27/06/2018.
//  Copyright © 2018 Pandastic Games. All rights reserved.
//

public class TmpFileMgr {
    var path:URL?
    let DIR_NAME = "tmpfilemgr"
    
    public static let instance = TmpFileMgr()
    
    public init() {
        let fileManager:FileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        path = directory.appendingPathComponent(DIR_NAME)
        
        if let path = path {
            let fileManager = FileManager.default
            _ = try? fileManager.createDirectory(atPath:path.path,withIntermediateDirectories:true)
        }
        deleteFiles()
    }
    
    func deleteFiles() {
        guard let path = path else { return }
        
        let fileManager:FileManager = FileManager.default
        if let files = try? fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]) {
            files.forEach { _ = try? fileManager.removeItem(at: $0) }
        }
    }
    
    public func Get() -> URL? {
        guard let path = path else { return nil }
        let key = UUID().uuidString
        return path.appendingPathComponent(key)
    }
    
    public static func Delete(_ url:URL?) {
        guard let url = url else { return }
        let fileManager:FileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            _ = try? fileManager.removeItem(at: url)
        }
    }
}
