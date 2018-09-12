//
//  WeakRef.swift
//  Networkamp
//
//  Created by woko on 02/07/2018.
//  Copyright © 2018 Pandastic Games. All rights reserved.
//

import UIKit

public class WeakRef<T> where T: AnyObject {
    
    private(set) weak var value: T?
    
    public init(value: T?) {
        self.value = value
    }
    
    public func Get() -> T? {
        return value
    }
}

public class WeakRefStore<T> where T: AnyObject {
    
    public init() {
        array = [WeakRef<T>]()
    }
    
    public init(values:[T]) {
        array = values.map { WeakRef(value:$0) }
    }
    
    var array:[WeakRef<T>]
    
    public func Add(_ val:T) {
        array.append(WeakRef(value:val))
    }
    
    public func AddIfNotExists(_ val:T) {
        if !Contains(val) {
            array.append(WeakRef(value:val))
        }
    }
    
    public func Remove(_ val:T) {
        array = array.filter({
            if let item = $0.value, !equals(item, val) {
                return true
            }
            return false
        })
    }
    
    public func IsOnlyElement(_ val:T) -> Bool {
        let items = Get()
        return items.count == 1 && equals(items[0], val)
    }
    
    public func Contains(_ val:T) -> Bool {
        return Get().contains { equals($0, val) }
    }
    
    public func Get() -> [T] {
        return array.filter({ $0.value != nil }).map({ $0.value! })
    }
    
    func equals(_ left:T, _ right:T) -> Bool {
        return left === right
    }
}

public class WeakRefStoreEq<T> where T: AnyObject & Equatable {
    
    public init() {
        array = [WeakRef<T>]()
    }
    
    public init(values:[T]) {
        array = values.map { WeakRef(value:$0) }
    }
    
    var array:[WeakRef<T>]
    
    public func Add(_ val:T) {
        array.append(WeakRef(value:val))
    }
    
    public func Remove(_ val:T) {
        array = array.filter({
            if let item = $0.value, !equals(item, val) {
                return true
            }
            return false
        })
    }
    
    public func IsOnlyElement(_ val:T) -> Bool {
        let items = Get()
        return items.count == 1 && equals(items[0], val)
    }
    
    public func Contains(_ val:T) -> Bool {
        return Get().contains { equals($0, val) }
    }
    
    public func Get() -> [T] {
        return array.filter({ $0.value != nil }).map({ $0.value! })
    }
    
    func equals(_ left:T, _ right:T) -> Bool {
        return left == right
    }
}
