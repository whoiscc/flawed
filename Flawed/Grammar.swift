//
//  Grammar.swift
//  Flawed
//
//  Created by Cowsay on 2019/1/17.
//  Copyright (c) 2019 Cowsay. All rights reserved.
//

import Foundation


// program : stat NEWLINE program | stat NEWLINE | stat
// stat : assign | ifthenelse | INDENT program DEDENT
// ifthenelse: IF expr THEN stat ELSE stat
// assign : ID ASSIGN expr
// expr : expr2 OP1 expr | expr2 | func
// func : FUNC farg RASSIGN stat
// farg : ID COMMA farg | ID | <e>
// expr2 : expr3 OP2 expr2 | expr3
// expr3 : OP expr3 | expr4
// # expr4 : expr4 OPEN arg CLOSE | expr5
// expr4 : expr5 expr4' | expr5
// expr4' : OPEN arg CLOSE expr4' | <e>
// arg : expr COMMA arg | expr | <e>
// expr5 : NUM | ID | OPEN expr CLOSE
public struct Statement {
    indirect enum Kind {
        case assignment(String, Expression)
        case condition(Expression, Statement, Statement)
        case block([Statement])
    }
    let kind: Kind, tokens: Range<Int>
}

public struct Expression {
    indirect enum Kind {
        case number(Int)
        case identifier(String)
        case calling(Expression, [Expression])
        case function([String], Statement)
    }
    let kind: Kind, tokens: Range<Int>
}

public enum ExpectedToken {
    case number
    case identifier
    case assign
    case open, close
    case then, else_
    case indent, dedent
    case if_
    case func_, rassign
    case comma
    
    func match(_ token: Token.Kind) -> Bool {
        switch self {
        case .number:
            if case .number = token {
                return true
            }
        case .identifier:
            if case .identifier = token {
                return true
            }
        case .assign:
            if case .assign = token {
                return true
            }
        case .open:
            if case .open = token {
                return true
            }
        case .close:
            if case .close = token {
                return true
            }
        case .then:
            if case .then = token {
                return true
            }
        case .else_:
            if case .else_ = token {
                return true
            }
        case .indent:
            if case .indent = token {
                return true
            }
        case .dedent:
            if case .dedent = token {
                return true
            }
        case .if_:
            if case .if_ = token {
                return true
            }
        case .func_:
            if case .func_ = token {
                return true
            }
        case .rassign:
            if case .rassign = token {
                return true
            }
        case .comma:
            if case .comma = token {
                return true
            }
        }
        return false
    }
}

public enum ParseError: Error {
    case unexpectedToken(at: Token, expected: [ExpectedToken])
}

func skip(
    _ tokens: [Token], _ expect: ExpectedToken, _ offset: inout Int,
    _ fail: Bool = false
) throws {
    if expect.match(tokens[offset].kind) {
        offset += 1
    } else {
        if fail {
            preconditionFailure()
        } else {
            throw ParseError.unexpectedToken(
                at: tokens[offset], expected: [expect])
        }
    }
}

public func parse(tokens: [Token]) throws -> Statement {
    var _offset = 0
    let node = try parseProgram(tokens, &_offset)
    return node
}

func parseProgram(
    _ source: [Token], _ offset: inout Int
) throws -> Statement {
    let start = offset
    var statements = [Statement]()
    while true {
        if case .end = source[offset].kind {
            break
        }
        if case .dedent = source[offset].kind {
            break
        }
        let stat = try parseStat(source, &offset)
        statements.append(stat)
        if case .newline = source[offset].kind {
            offset += 1
        }
    }
    return Statement(kind: .block(statements), tokens: start..<offset)
}

func parseStat(
    _ source: [Token], _ offset: inout Int
) throws -> Statement {
    switch source[offset].kind {
    case .identifier:
        return try parseAssign(source, &offset)
    case .if_:
        return try parseIfThenElse(source, &offset)
    case .indent:
        offset += 1
        let stat = try parseProgram(source, &offset)
        try skip(source, .dedent, &offset)
        return stat
    default:
        throw ParseError.unexpectedToken(
            at: source[offset], expected: [.identifier, .if_, .indent])
    }
}

func parseAssign(
    _ source: [Token], _ offset: inout Int
) throws -> Statement {
    let start = offset
    guard case .identifier(let name) = source[offset].kind else {
        preconditionFailure()
    }
    offset += 1
    try skip(source, .assign, &offset)
    let expr = try parseExpr(source, &offset)
    return Statement(kind: .assignment(name, expr), tokens: start..<offset)
}

func parseIfThenElse(
    _ source: [Token], _ offset: inout Int
) throws -> Statement {
    let start = offset
    try skip(source, .if_, &offset, true)
    let cond = try parseExpr(source, &offset)
    try skip(source, .then, &offset)
    let trueStat = try parseStat(source, &offset)
    try skip(source, .else_, &offset)
    let falseStat = try parseStat(source, &offset)
    return Statement(
        kind: .condition(cond, trueStat, falseStat),
        tokens: start..<offset
    )
}

func parseExprImpl(
    _ source: [Token], _ offset: inout Int,
    _ prefixSet: String, _ next: ([Token], inout Int) throws -> Expression
) throws -> Expression {
    let start = offset
    let left = try next(source, &offset)
    switch (source[offset].kind) {
    case .operator_(let op) where prefixSet.contains(op.first!):
        let opPos = offset
        offset += 1
        let right = try parseExprImpl(source, &offset, prefixSet, next)
        return Expression(
            kind: .calling(
                Expression(kind: .identifier(op), tokens: opPos..<opPos + 1),
                [left, right]
            ),
            tokens: start..<offset
        )
    default:
        return left
    }
}

func parseExpr(
    _ source: [Token], _ offset: inout Int
) throws -> Expression {
    if case .func_ = source[offset].kind {
        return try parseFunc(source, &offset)
    } else {
        return try parseExprImpl(source, &offset, "$", parseExpr2)
    }
}

func parseFunc(
    _ source: [Token], _ offset: inout Int
) throws -> Expression {
    let start = offset
    try skip(source, .func_, &offset, true)
    var fargList = [String]()
    while true {
        if case .rassign = source[offset].kind {
            break
        }
        guard case .identifier(let name) = source[offset].kind else {
            throw ParseError.unexpectedToken(
                at: source[offset], expected: [.identifier])
        }
        fargList.append(name)
        offset += 1
        if case .comma = source[offset].kind {
            try skip(source, .comma, &offset)
        }
    }
    try skip(source, .rassign, &offset, true)
    let body = try parseStat(source, &offset)
    return Expression(kind: .function(fargList, body), tokens: start..<offset)
}

func parseExpr2(
    _ source: [Token], _ offset: inout Int
) throws -> Expression {
    return try parseExprImpl(source, &offset, "&|^", parseExpr3)
}

func parseExpr3(
    _ source: [Token], _ offset: inout Int
) throws -> Expression {
    return try parseExprImpl(source, &offset, "~=<>", parseExpr4)
}

func parseExpr4(
    _ source: [Token], _ offset: inout Int
) throws -> Expression {
    return try parseExprImpl(source, &offset, "+-", parseExpr5)
}

func parseExpr5(
    _ source: [Token], _ offset: inout Int
) throws -> Expression {
    return try parseExprImpl(source, &offset, "*/", parseExpr6)
}

func parseExpr6(
    _ source: [Token], _ offset: inout Int
) throws -> Expression {
    return try parseExprImpl(source, &offset, "@", parseExprU)
}

func parseExprU(
    _ source: [Token], _ offset: inout Int
) throws -> Expression {
    let start = offset
    if case .operator_(let op) = source[offset].kind {
        offset += 1
        let expr = try parseExprC(source, &offset)
        return Expression(
            kind: .calling(
                Expression(kind: .identifier(op), tokens: start..<start + 1),
                [expr]
            ),
            tokens: start..<offset
        )
    } else {
        return try parseExprC(source, &offset)
    }
}

func parseExprC(
    _ source: [Token], _ offset: inout Int
) throws -> Expression {
    let start = offset
    let firstFunc = try parseExprA(source, &offset)
    if case .open = source[offset].kind {
        let callingList = try parseExprC_(source, &offset)
        var expr = firstFunc
        for argList in callingList {
            expr = Expression(kind: .calling(expr, argList), tokens: start..<offset)
        }
        return expr
    } else {
        return firstFunc
    }
}

func parseExprC_(
    _ source: [Token], _ offset: inout Int
) throws -> [[Expression]] {
    var callingList = [[Expression]]()
    while case .open = source[offset].kind {
        offset += 1
        var argList = [Expression]()
        while true {
            if case .close = source[offset].kind {
                offset += 1
                break
            }
            let expr = try parseExpr(source, &offset)
            argList.append(expr)
            if case .comma = source[offset].kind {
                offset += 1
            }
        }
        callingList.append(argList)
    }
    return callingList
}

func parseExprA(
    _ source: [Token], _ offset: inout Int
) throws -> Expression {
    switch (source[offset].kind) {
    case .number(let num):
        offset += 1
        return Expression(kind: .number(num), tokens: offset - 1..<offset)
    case .identifier(let id):
        offset += 1
        return Expression(kind: .identifier(id), tokens: offset - 1..<offset)
    case .open:
        offset += 1
        let expr = try parseExpr(source, &offset)
        try skip(source, .close, &offset)
        return expr
    default:
        throw ParseError.unexpectedToken(
            at: source[offset], expected: [.number, .identifier, .open])
    }
}
