//
//  KeyChainAccess.swift
//
//  Created by William Thompson on 1/5/18.
//  Copyright © 2018 William Thompson. All rights reserved.
//
//  A rewrite of http://www.raywenderlich.com/6475/basic-security-in-ios-5-tutorial-part-1 KeychainWrapper.h and KeychainWrapper.m
//
//
//

import Foundation

private let SecMatchLimit: String! = kSecMatchLimit as String
private let SecReturnData: String! = kSecReturnData as String
private let SecReturnPersistentRef: String! = kSecReturnPersistentRef as String
private let SecValueData: String! = kSecValueData as String
private let SecAttrAccessible: String! = kSecAttrAccessible as String
private let SecClass: String! = kSecClass as String
private let SecAttrService: String! = kSecAttrService as String
private let SecAttrGeneric: String! = kSecAttrGeneric as String
private let SecAttrAccount: String! = kSecAttrAccount as String
private let SecAttrAccessGroup: String! = kSecAttrAccessGroup as String
private let SecReturnAttributes: String = kSecReturnAttributes as String

open class KeyChainAccess {
    
    public static let defaultKeyChainAccess = KeyChainAccess.standard
    public static let standard = KeyChainAccess()
    private (set) public var serviceName: String
    private (set) public var accessGroup: String?
    private static let defaultServiceName: String = {
        return Bundle.main.bundleIdentifier
        }()!
    
    private convenience init() {
        self.init(serviceName: KeyChainAccess.defaultServiceName)
    }
    
    public init(serviceName: String, accessGroup: String? = nil) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
    }
    
    open func hasValue(forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> Bool {
       return true
    }
    
    open func accessibiltyOfKey(_ key: String) -> KeyChainAccessibility? {
        var keyChainQueryDictionary = setupKeyChainQueryDictionary(forKey: key)
        keyChainQueryDictionary.removeValue(forKey: SecAttrAccessible)
        keyChainQueryDictionary[SecMatchLimit] = kSecMatchLimitOne
        keyChainQueryDictionary[SecReturnAttributes] = kCFBooleanTrue
        var result: AnyObject?
        let status = SecItemCopyMatching(keyChainQueryDictionary as CFDictionary, &result)
        guard status == noErr, let resultsDictionary = result as? [String:AnyObject], let accessibilityAttrValue = resultsDictionary[SecAttrAccessible] as? String else {
            return nil
        }
        return KeyChainAccessibility.accessibilityForAttributeValue(accessibilityAttrValue as CFString)
    }
    
    open func allKeys() -> Set<String> {
        var keyChainQueryDictionary: [String:Any] = [
            SecClass: kSecClassGenericPassword,
            SecAttrService: serviceName,
            SecReturnAttributes: kCFBooleanTrue,
            SecMatchLimit: kSecMatchLimitAll,
            ]
        if let accessGroup = self.accessGroup {
            keyChainQueryDictionary[SecAttrAccessGroup] = accessGroup
        }
        var result: AnyObject?
        let status = SecItemCopyMatching(keyChainQueryDictionary as CFDictionary, &result)
        guard status == errSecSuccess else { return [] }
        var keys = Set<String>()
        if let results = result as? [[AnyHashable: Any]] {
            for attributes in results {
                if let accountData = attributes[SecAttrAccount] as? Data,
                    let account = String(data: accountData, encoding: String.Encoding.utf8) {
                    keys.insert(account)
                }
            }
        }
        return keys
    }
    
    open func integer(forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> Int? {
        guard let numberValue = object(forKey: key, withAccessibility: accessibility) as? NSNumber else {
            return 0
        }
        return numberValue.intValue
    }
    
    open func float(forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> Float? {
        guard let numberValue = object(forKey: key, withAccessibility: accessibility) as? NSNumber else {
            return nil
        }
        return numberValue.floatValue
    }
    
    open func double(forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> Double? {
        guard let numberValue = object(forKey: key, withAccessibility: accessibility) as? NSNumber else {
            return nil
        }
        return numberValue.doubleValue
    }
    
    open func bool(forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> Bool? {
        guard let numberValue = object(forKey: key, withAccessibility: accessibility) as? NSNumber else {
            return false
        }
        return numberValue.boolValue
    }
    
    open func string(forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> String? {
        guard let keyChainData = data(forKey: key, withAccessibility: accessibility) else {
            return nil
        }
        return String(data: keyChainData, encoding: String.Encoding.utf8) as String?
    }
    
    open func object(forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> NSCoding? {
        guard let keyChainData = data(forKey: key, withAccessibility: accessibility) else {
            return nil
        }
        return NSKeyedUnarchiver.unarchiveObject(with: keyChainData) as? NSCoding
    }
    
    open func data(forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> Data? {
        var keyChainQueryDictionary = setupKeyChainQueryDictionary(forKey: key, withAccessibility: accessibility)
        keyChainQueryDictionary[SecMatchLimit] = kSecMatchLimitOne
        keyChainQueryDictionary[SecReturnData] = kCFBooleanTrue
        var result: AnyObject?
        let status = SecItemCopyMatching(keyChainQueryDictionary as CFDictionary, &result)
        return status == noErr ? result as? Data : nil
    }
    
    open func dataRef(forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> Data? {
        var keyChainQueryDictionary = setupKeyChainQueryDictionary(forKey: key, withAccessibility: accessibility)
        keyChainQueryDictionary[SecMatchLimit] = kSecMatchLimitOne
        keyChainQueryDictionary[SecReturnPersistentRef] = kCFBooleanTrue
        var result: AnyObject?
        let status = SecItemCopyMatching(keyChainQueryDictionary as CFDictionary, &result)
        
        return status == noErr ? result as? Data : nil
    }
    
    @discardableResult open func set(_ value: Int, forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> Bool {
        return set(NSNumber(value: value), forKey: key, withAccessibility: accessibility)
    }
    
    @discardableResult open func set(_ value: Float, forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> Bool {
        return set(NSNumber(value: value), forKey: key, withAccessibility: accessibility)
    }
    
    @discardableResult open func set(_ value: Double, forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> Bool {
        return set(NSNumber(value: value), forKey: key, withAccessibility: accessibility)
    }
    
    @discardableResult open func set(_ value: Bool, forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> Bool {
        return set(NSNumber(value: value), forKey: key, withAccessibility: accessibility)
    }
    
    @discardableResult open func set(_ value: String, forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> Bool {
        if let data = value.data(using: .utf8) {
            return set(data, forKey: key, withAccessibility: accessibility)
        } else {
            return false
        }
    }
    
    @discardableResult open func set(_ value: NSCoding, forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> Bool {
        let data = NSKeyedArchiver.archivedData(withRootObject: value)
        return set(data, forKey: key, withAccessibility: accessibility)
    }
    
    @discardableResult open func set(_ value: Data, forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> Bool {
        var keyChainQueryDictionary: [String:Any] = setupKeyChainQueryDictionary(forKey: key, withAccessibility: accessibility)
        keyChainQueryDictionary[SecValueData] = value
        if let accessibility = accessibility {
            keyChainQueryDictionary[SecAttrAccessible] = accessibility.keyChainAttrValue
        } else {
            keyChainQueryDictionary[SecAttrAccessible] = KeyChainAccessibility.whenUnlocked.keyChainAttrValue
        }
        let status: OSStatus = SecItemAdd(keyChainQueryDictionary as CFDictionary, nil)
        if status == errSecSuccess {
            return true
        } else if status == errSecDuplicateItem {
            return update(value, forKey: key, withAccessibility: accessibility)
        } else {
            return false
        }
    }
    
    @available(*, deprecated: 2.2.1, message: "remove is deprecated, use removeObject instead")
    @discardableResult open func remove(key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> Bool {
        return removeObject(forKey: key, withAccessibility: accessibility)
    }
    
    @discardableResult open func removeObject(forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> Bool {
        let keyChainQueryDictionary: [String:Any] = setupKeyChainQueryDictionary(forKey: key, withAccessibility: accessibility)
        
        // Delete
        let status: OSStatus = SecItemDelete(keyChainQueryDictionary as CFDictionary)
        
        if status == errSecSuccess {
            return true
        } else {
            return false
        }
    }
    
    open func removeAllKeys() -> Bool {
        var keyChainQueryDictionary: [String:Any] = [SecClass:kSecClassGenericPassword]
        keyChainQueryDictionary[SecAttrService] = serviceName
        if let accessGroup = self.accessGroup {
            keyChainQueryDictionary[SecAttrAccessGroup] = accessGroup
        }
        let status: OSStatus = SecItemDelete(keyChainQueryDictionary as CFDictionary)
        if status == errSecSuccess {
            return true
        } else {
            return false
        }
    }
    
    open class func wipeKeychain() {
        deleteKeyChainSecClass(kSecClassGenericPassword)
        deleteKeyChainSecClass(kSecClassInternetPassword)
        deleteKeyChainSecClass(kSecClassCertificate)
        deleteKeyChainSecClass(kSecClassKey)
        deleteKeyChainSecClass(kSecClassIdentity)
    }
    
    @discardableResult private class func deleteKeyChainSecClass(_ secClass: AnyObject) -> Bool {
        let query = [SecClass: secClass]
        let status: OSStatus = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            return true
        } else {
            return false
        }
    }
    
    private func update(_ value: Data, forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> Bool {
        var keyChainQueryDictionary: [String:Any] = setupKeyChainQueryDictionary(forKey: key, withAccessibility: accessibility)
        let updateDictionary = [SecValueData:value]
        if let accessibility = accessibility {
            keyChainQueryDictionary[SecAttrAccessible] = accessibility.keyChainAttrValue
        }
        let status: OSStatus = SecItemUpdate(keyChainQueryDictionary as CFDictionary, updateDictionary as CFDictionary)
        
        if status == errSecSuccess {
            return true
        } else {
            return false
        }
    }
    
    private func setupKeyChainQueryDictionary(forKey key: String, withAccessibility accessibility: KeyChainAccessibility? = nil) -> [String:Any] {
        var keyChainQueryDictionary: [String:Any] = [SecClass:kSecClassGenericPassword]
        keyChainQueryDictionary[SecAttrService] = serviceName
        if let accessibility = accessibility {
            keyChainQueryDictionary[SecAttrAccessible] = accessibility.keyChainAttrValue
        }
        if let accessGroup = self.accessGroup {
            keyChainQueryDictionary[SecAttrAccessGroup] = accessGroup
        }
        let encodedIdentifier: Data? = key.data(using: String.Encoding.utf8)
        keyChainQueryDictionary[SecAttrGeneric] = encodedIdentifier
        keyChainQueryDictionary[SecAttrAccount] = encodedIdentifier
        return keyChainQueryDictionary
    }
    
}
