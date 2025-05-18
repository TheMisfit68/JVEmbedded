//
//  JVSingleton protocol.swift
//
//  Created by Administrator on 14/09/14.
//  Copyright (c) 2014 OneClick. All rights reserved.
//

public protocol Singleton{
	
    associatedtype SingletonType = Self // Use the type of the class that will later conform to this protocol as a typedefinition here
    
    static var shared: SingletonType { get }
    
    // Always provide a private initializer in the conforming class to prevent instantiaton without use of the 'shared'-variable
}
