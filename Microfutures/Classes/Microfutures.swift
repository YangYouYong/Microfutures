//
//  Future.swift
//  Microfutures
//
//  Created by Fernando on 27/1/17.
//  Copyright © 2017 Fernando. All rights reserved.
//

import Foundation

public enum Result<T> {
    case success(T)
    case failure(Error)
}

public struct Future<T> {
    public typealias ResultType = Result<T>
    public typealias Completion = (ResultType) -> ()
    public typealias AsyncOperation = (Completion) -> ()
    
    private let operation: AsyncOperation
    
    public init(result: ResultType) {
        self.init(operation: { completion in
            completion(result)
        })
    }
    
    public init(value: T) {
        self.init(result: .success(value))
    }
    
    public init(error: Error) {
        self.init(result: .failure(error))
    }
    
    public init(operation: @escaping AsyncOperation) {
        self.operation = operation
    }
    
    fileprivate func then(_ completion: Completion) {
        self.operation() { result in
            completion(result)
        }
    }
    
    public func subscribe(onNext: @escaping (T) -> Void = { _ in }, onError: @escaping (Error) -> Void = { _ in }) {
        self.then { result in
            switch result {
            case .success(let value): onNext(value)
            case .failure(let error): onError(error)
            }
        }
    }
}

extension Future {
    public func map<U>(_ f: @escaping (T) -> U) -> Future<U> {
        return Future<U>(operation: { completion in
            self.then { result in
                switch result {
                case .success(let valueBox): completion(Result.success(f(valueBox)))
                case .failure(let errorBox): completion(Result.failure(errorBox))
                }
            }
        })
    }
    
    public func flatMap<U>(_ f: @escaping (T) -> Future<U>) -> Future<U> {
        return Future<U>(operation: { completion in
            self.then { firstFutureResult in
                switch firstFutureResult {
                case .success(let valueBox): f(valueBox).then(completion)
                case .failure(let errorBox): completion(Result.failure(errorBox))
                }
            }
        })
    }
}