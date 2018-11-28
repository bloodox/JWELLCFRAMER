//
//  KeyChainAccessibility.swift
//
//  Created by William Thompson on 1/5/18.
//  Copyright © 2018 William Thompson. All rights reserved.
//
//  A rewrite of http://www.raywenderlich.com/6475/basic-security-in-ios-5-tutorial-part-1 KeychainWrapper.h and KeychainWrapper.m
//
//
//

import Foundation

protocol KeyChainAttrRepresentable {
    var keyChainAttrValue: CFString { get }
}

public enum KeyChainAccessibility {
    
    @available(iOS 4, *)
    case afterFirstUnlock
    
    @available(iOS 4, *)
    case afterFirstUnlockThisDeviceOnly
    
    @available(iOS 4, *)
    case always
    
    @available(iOS 8, *)
    case whenPasscodeSetThisDeviceOnly
    
    @available(iOS 4, *)
    case alwaysThisDeviceOnly
    
    @available(iOS 4, *)
    case whenUnlocked
    
    @available(iOS 4, *)
    case whenUnlockedThisDeviceOnly
    
    static func accessibilityForAttributeValue(_ keychainAttrValue: CFString) -> KeyChainAccessibility? {
        for (key, value) in keychainItemAccessibilityLookup {
            if value == keychainAttrValue {
                return key
            }
        }
        return nil
    }
}

private let keychainItemAccessibilityLookup: [KeyChainAccessibility:CFString] = {
    var lookup: [KeyChainAccessibility:CFString] = [
        .afterFirstUnlock: kSecAttrAccessibleAfterFirstUnlock,
        .afterFirstUnlockThisDeviceOnly: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        .always: kSecAttrAccessibleAlways,
        .whenPasscodeSetThisDeviceOnly: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
        .alwaysThisDeviceOnly : kSecAttrAccessibleAlwaysThisDeviceOnly,
        .whenUnlocked: kSecAttrAccessibleWhenUnlocked,
        .whenUnlockedThisDeviceOnly: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    ]
    
    return lookup
}()

extension KeyChainAccessibility : KeyChainAttrRepresentable {
    internal var keyChainAttrValue: CFString {
        return keychainItemAccessibilityLookup[self]!
    }
}





