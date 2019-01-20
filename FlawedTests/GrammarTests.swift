//
//  GrammarTests.swift
//  FlawedTests
//
//  Created by Cowsay on 2019/1/18.
//  Copyright (c) 2019 Cowsay. All rights reserved.
//

import XCTest
@testable import Flawed

class GrammarTests: XCTestCase {
    
    func testParse() {
        let sources: [([Token], LangNode.Statement)] = [(
            [
                .identifier("x"),
                .assign,
                .number(42),
                .end,
            ],
            .block([
                .assignment(
                    "x",
                    .number(42)
                )
            ])
        ), (
            [
                .identifier("y"),
                .assign,
                .identifier("x"),
                .operator_("+"),
                .number(1),
                .end,
            ],
            .block([
                .assignment(
                    "y",
                    .calling(
                        .identifier("+"), [
                            .identifier("x"),
                            .number(1)
                        ]
                    )
                )
            ])
        ), (
            [
                .identifier("x"),
                .assign,
                .number(42),
                .newline,
                .identifier("y"),
                .assign,
                .identifier("x"),
                .operator_("+"),
                .number(1),
                .end,
            ],
            .block([
                .assignment(
                    "x",
                    .number(42)
                ),
                .assignment(
                    "y",
                    .calling(
                        .identifier("+"), [
                            .identifier("x"),
                            .number(1)
                        ]
                    )
                )
            ])
        ), (
            [
                .identifier("z"),
                .assign,
                .identifier("abs"),
                .open,
                .operator_("-"),
                .identifier("x"),
                .close,
                .end,
            ],
            .block([
                .assignment(
                    "z",
                    .calling(
                        .identifier("abs"), [
                            .calling(
                                .identifier("-"), [
                                    .identifier("x")
                                ]
                            )
                        ]
                    )
                ),
            ])
        )]
        for (source, expectedNode) in sources {
            let node: LangNode.Statement? = try? parse(tokens: source)
            XCTAssertEqual("\(node!)", "\(expectedNode)")
        }
    }
    
    func testParseError() {
        let sources: [[Token]] = [
            [
                .assign,
                .end,
            ],
            [
                .identifier("x"),
                .assign,
                .end,
            ]
        ]
        for source in sources {
            XCTAssertThrowsError(try parse(tokens: source))
        }
    }
    
    func testParsePerformance() {
        var longSource: [Token] = [.identifier("x"), .assign, .number(0)]
        for i in 0 ..< 10000 {
            if Bool.random() {
                longSource.append(.operator_("*"))
            } else {
                longSource.append(.operator_("+"))
            }
            longSource.append(.number(i + 1))
        }
        longSource.append(.end)
        self.measure {
            _ = try! parse(tokens: longSource)
        }
    }
    
}
