//
//  TokenBucket.swift
//  TokenBucket
//
//  Created by Paulo Andrade on 15/03/2018.
//  Copyright © 2018 Paulo Andrade. All rights reserved.
//

import Foundation

public class TokenBucket: NSObject {
    
    public let capacity: Int
    public private(set) var replenishingInterval: TimeInterval
    public private(set) var tokensPerInterval: Int
    
    private var _tokenCount: Int
    public var tokenCount: Int {
        replenish()
        return _tokenCount
    }
    private var lastReplenished: Date
    
    public init(capacity: Int, tokensPerInterval: Int, interval: TimeInterval, initialTokenCount: Int = 0) {
        guard interval > 0.0 else {
            fatalError("interval must be a positive number")
        }
        self.capacity = capacity
        self.tokensPerInterval = tokensPerInterval
        self.replenishingInterval = interval
        self._tokenCount = min(capacity, initialTokenCount)
        self.lastReplenished = Date()
    }
    
    public func consume(_ count: Int) {
        guard count <= capacity else {
            fatalError("Cannot consume \(count) amount of tokens on a bucket with capacity \(capacity)")
        }
        
        let _ = tryConsume(count, until: Date.distantFuture)
    }
    
    public func tryConsume(_ count: Int, until limitDate: Date) -> Bool {
        guard count <= capacity else {
            fatalError("Cannot consume \(count) amount of tokens on a bucket with capacity \(capacity)")
        }
        
        return wait(until: limitDate, for: count)
    }
    
    
    private let condition = NSCondition()
    private func replenish() {
        condition.lock()
        let ellapsedTime = abs(lastReplenished.timeIntervalSinceNow)
        if  ellapsedTime > replenishingInterval {
            let ellapsedIntervals = Int((floor(ellapsedTime / Double(replenishingInterval))))
            _tokenCount = min(_tokenCount + (ellapsedIntervals * tokensPerInterval), capacity)
            lastReplenished = Date()
            condition.signal()
        }
        condition.unlock()
    }
    
    private func wait(until limitDate: Date, for tokens: Int) -> Bool {
        condition.lock()
        defer {
            condition.unlock()
        }
        while _tokenCount < tokens {
            DispatchQueue.global().async {
                self.replenish()
            }
            if limitDate < Date() {
                return false
            }
            condition.wait(until: Date().addingTimeInterval(0.2))
        }
        _tokenCount -= tokens
        return true
    }
}
