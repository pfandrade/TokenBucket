//
//  TokenBucketTests.swift
//  TokenBucketTests
//
//  Created by Paulo Andrade on 15/03/2018.
//  Copyright © 2018 Paulo Andrade. All rights reserved.
//

import XCTest
@testable import TokenBucket

class TokenBucketTests: XCTestCase {
    
    func testReplenishing() {
        let bucket = TokenBucket(capacity: 10, tokensPerInterval: 1, interval: 0.5)
        XCTAssertEqual(bucket.tokenCount, 0)
        XCTAssertFalse(bucket.tryConsume(1, until: Date().addingTimeInterval(0.01)))
        
        // wait long enough for the first replenish
        Thread.sleep(until: Date().addingTimeInterval(0.6))
        // and try again
        XCTAssertTrue(bucket.tryConsume(1, until: Date().addingTimeInterval(0.1)))
        XCTAssertEqual(bucket.tokenCount, 0)
    }
    
    func testInitialTokens() {
        // validated initial token is working
        let bucket0 = TokenBucket(capacity: 10, tokensPerInterval: 1, interval: 5.0)
        XCTAssertEqual(bucket0.tokenCount, 0)
        
        let bucket7 = TokenBucket(capacity: 10, tokensPerInterval: 1, interval: 5.0, initialTokenCount: 7)
        XCTAssertEqual(bucket7.tokenCount, 7)
    }
    
    func testCapacity() {
        // we should never overflow our capacity
        let bucket = TokenBucket(capacity: 10, tokensPerInterval: 7, interval: 0.2)
        XCTAssertEqual(bucket.tokenCount, 0)
        
        // wait long enough for the two replenish
        Thread.sleep(until: Date().addingTimeInterval(0.6))
        XCTAssertEqual(bucket.tokenCount, 10)
    }
    
    func testConcurrency() {
        var dateBuffer: [Date] = []
        let dateQueue = DispatchQueue(label: "Date Buffer Writing Queue")
        let bucket = TokenBucket(capacity: 10, tokensPerInterval: 1, interval: 0.3)
        
        let globalQueue = DispatchQueue.global()
        var expectations: [XCTestExpectation] = []
        (0..<20).forEach { (i) in
            let expectation = self.expectation(description: "block \(i)")
            globalQueue.async {
                bucket.consume(1)
                dateQueue.sync {
                    dateBuffer.append(Date())
                }
                expectation.fulfill()
            }
            expectations.append(expectation)
        }
        
        wait(for: expectations, timeout: 10.0)
        
        // there should be 20 dates on the buffers
        XCTAssertEqual(dateBuffer.count, 20)
        // spaced by roughly 0.3 seconds
        dateBuffer.enumerated().forEach { (idx, date) in
            guard idx > 0 else {
                return
            }
            XCTAssertEqual(date.timeIntervalSince(dateBuffer[idx-1]), 0.3, accuracy: 0.2)
        }
    }
}
