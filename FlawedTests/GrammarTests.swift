//
//  GrammarTests.swift
//  FlawedTests
//
//  Created by Cowsay on 2019/1/18.
//  Copyright (c) 2019 Cowsay. All rights reserved.
//

import XCTest
@testable import Flawed

func fakePos(_ kind: Token.Kind) -> Token {
    return Token(kind: kind, beginLine: 0, beginColumn: 0, endLine: 0, endColumn: 0)
}

class GrammarTests: XCTestCase {
    
    func testParse() {
        let sources: [([Token.Kind], LangNode.Statement)] = [(
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
            let node: LangNode.Statement? = try? parse(tokens: source.map(fakePos))
            XCTAssertEqual("\(node!)", "\(expectedNode)")
        }
    }
    
    func testParseError() {
        let sources: [[Token.Kind]] = [
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
            XCTAssertThrowsError(try parse(tokens: source.map(fakePos)))
        }
    }
    
    func testParsePerformance() {
        var longSource: [Token] = [
            fakePos(.identifier("x")),
            fakePos(.assign),
            fakePos(.number(0))
        ]
        for i in 0 ..< 10000 {
            if Bool.random() {
                longSource.append(fakePos(.operator_("*")))
            } else {
                longSource.append(fakePos(.operator_("+")))
            }
            longSource.append(fakePos(.number(i + 1)))
        }
        longSource.append(fakePos(.end))
        self.measure {
            _ = try! parse(tokens: longSource)
        }
    }
    
}
