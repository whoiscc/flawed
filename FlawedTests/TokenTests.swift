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
                .number(1),
                .operator_("+"),
                .number(2),
                .end,
            ]
        ), (
            "x <- x + 1",
            [
                .identifier("x"),
                .assign,
                .identifier("x"),
                .operator_("+"),
                .number(1),
                .end,
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
