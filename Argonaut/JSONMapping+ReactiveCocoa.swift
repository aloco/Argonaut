//
//  JSONMapping+ReactiveCocoa.swift
//  Example
//
//  Created by Alexander Schuch on 03/04/15.
//  Copyright (c) 2015 Alexander Schuch. All rights reserved.
//

import Foundation
import Argo
import ReactiveCocoa
import Result

public let ArgonautErrorDomain = "com.aschuch.Argonaut.ErrorDomain"

public enum ArgonautError: ErrorType {
    case Decoding(type: String, reason: String)
    case Underlying(ErrorType)
    
    public var nsError: NSError {
        switch self {
        case let .Decoding(type, reason):
            let info = [NSLocalizedFailureReasonErrorKey: "\(type): \(reason)"]
            return NSError(domain: ArgonautErrorDomain, code: -1, userInfo: info)
        case let .Underlying(error):
            return error as NSError
        }
    }
}

// MARK: ReactiveCocoa <= 2.x

@available(*, deprecated, message="RACSignal extensions will be removed as soon as ReactiveCocoa 4 becomes final.")
extension RACSignal {
    
    /// Maps the given JSON object (AnyObject) to an object of given classType
    ///
    /// - parameter classType: The type of the object that should be returned
    /// - returns: A new RACSignal emitting the decoded object
    public func mapToType<T: protocol<NSObjectProtocol, Decodable> where T == T.DecodedType>(classType: T.Type) -> RACSignal {
        return tryMap { (object, error) -> T! in
            let decoded: Decoded<T> = decode(object)
            
            switch decoded {
            case .Success(let value):
                return value
            case .Failure(let failure):
                if error != nil {
                    error.memory = ArgonautError.Decoding(type: String(T), reason: failure.description).nsError
                }
                return nil
            }
        }
    }
    
    
    /// Maps the given JSON object array to an array of objects of the given classType
    ///
    /// - parameter classType: The type of the array that should be returned
    /// - returns: A new RACSignal emitting an array of decoded objects
    public func mapToTypeArray<T: protocol<NSObjectProtocol, Decodable> where T == T.DecodedType>(classType: T.Type) -> RACSignal {
        return tryMap { (object, error) -> AnyObject! in
            let decoded: Decoded<[T]> = decode(object)
            
            switch decoded {
            case .Success(let value):
                return value
            case .Failure(let failure):
                if error != nil {
                    error.memory = ArgonautError.Decoding(type: "[\(String(T))]", reason: failure.description).nsError
                }
                return nil
            }
        }
    }
    
}


// MARK: ReactiveCocoa >= 4.x

extension SignalType where Value == AnyObject {
    
    /// Maps the given JSON object within the stream to an object of given classType
    ///
    /// - parameter classType: The type of the object that should be returned
    /// - returns: A new Signal emitting the decoded object
    public func mapToType<X: Decodable where X == X.DecodedType>(classType: X.Type) -> Signal<X, ArgonautError> {
        return mapError { ArgonautError.Underlying($0) }
            .attemptMap { object -> Result<X, ArgonautError> in
                let decoded: Decoded<X> = decode(object)
            
                switch decoded {
                case .Success(let value):
                    return .Success(value)
                case .Failure(let error):
                    return .Failure(ArgonautError.Decoding(type: String(X), reason: error.description))
                }
            }
    }
    
    /// Maps the given JSON object array within the stream to an array of objects of the given classType
    ///
    /// - parameter classType: The type of the array that should be returned
    /// - returns: A new Signal emitting an array of decoded objects
    public func mapToTypeArray<X: Decodable where X == X.DecodedType>(classType: X.Type) -> Signal<[X], ArgonautError> {
        return mapError { ArgonautError.Underlying($0) }
            .attemptMap { object -> Result<[X], ArgonautError> in
                let decoded: Decoded<[X]> = decode(object)
            
                switch decoded {
                case .Success(let value):
                    return .Success(value)
                case .Failure(let error):
                    return .Failure(ArgonautError.Decoding(type: "[\(String(X))]", reason: error.description))
                }
            }
    }
    
}

extension SignalProducerType where Value == AnyObject {
    
    /// Maps the given JSON object within the stream to an object of given classType
    ///
    /// - parameter classType: The type of the object that should be returned
    /// - returns: A new Signal emitting the decoded object
    public func mapToType<X: Decodable where X == X.DecodedType>(classType: X.Type) -> SignalProducer<X, ArgonautError> {
        return lift { $0.mapToType(classType) }
    }
    
    /// Maps the given JSON object array within the stream to an array of objects of the given classType
    ///
    /// - parameter classType: The type of the array that should be returned
    /// - returns: A new Signal emitting an array of decoded objects
    public func mapToTypeArray<X: Decodable where X == X.DecodedType>(classType: X.Type) -> SignalProducer<[X], ArgonautError> {
        return lift { $0.mapToTypeArray(classType) }
    }
    
}
