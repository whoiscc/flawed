//
//  TokenTests.swift
//  FlawedTests
//
//  Created by Cowsay on 2019/1/19.
//  Copyright (c) 2019 Cowsay. All rights reserved.
//

import XCTest
@testable import Flawed

class TokenTests: XCTestCase {

    func testScan() {
        let sources: [(String, [Token])] = [(
            "1 + 2",
            [
                Token(kind: .number(1), beginLine: 1, beginColumn: 1, endLine: 1, endColumn: 2),
                Token(kind: .operator_("+"), beginLine: 1, beginColumn: 3, endLine: 1, endColumn: 4),
                Token(kind: .number(2), beginLine: 1, beginColumn: 5, endLine: 1, endColumn: 6),
                Token(kind: .end, beginLine: 1, beginColumn: 6, endLine: 1, endColumn: 7),
            ]
        ), (
            "x <- x + 1",
            [
                Token(kind: .identifier("x"), beginLine: 1, beginColumn: 1, endLine: 1, endColumn: 2),
                Token(kind: .assign, beginLine: 1, beginColumn: 3, endLine: 1, endColumn: 5),
                Token(kind: .identifier("x"), beginLine: 1, beginColumn: 6, endLine: 1, endColumn: 7),
                Token(kind: .operator_("+"), beginLine: 1, beginColumn: 8, endLine: 1, endColumn: 9),
                Token(kind: .number(1), beginLine: 1, beginColumn: 10, endLine: 1, endColumn: 11),
                Token(kind: .end, beginLine: 1, beginColumn: 11, endLine: 1, endColumn: 12),
            ]
        )]
        for (source, expectedToken) in sources {
            let token = try? scan(source: source)
            XCTAssertEqual("\(token!)", "\(expectedToken)")
        }
    }

    func testScanPerformance() {
        var source = "x <- 0"
        for i in 0..<10000 {
            if Bool.random() {
                source += " +"
            } else {
                source += " *"
            }
            source += " \(i + 1)"
        }
        self.measure {
            _ = try! scan(source: source)
        }
    }

}
