//
//  Grammar.swift
//  Flawed
//
//  Created by Cowsay on 2019/1/17.
//  Copyright (c) 2019 Cowsay. All rights reserved.
//

import Foundation


// program : stat `\n` program | stat `\n` | stat
// stat : assign | IF expr THEN stat ELSE stat | INDENT program DEDENT
// assign : ID `<-` expr
// expr : expr2 OP1 expr | expr2
// expr2 : expr3 OP2 expr2 | expr3
// expr3 : OP expr3 | expr4
// # expr4 : expr4 `(` arg `)` | expr5
// expr4 : expr5 expr4' | expr5
// expr4' : `(` arg `)` expr4' | <e>
// arg : expr `,` arg | <e>
// expr5 : NUM | ID | `(` expr `)`
public struct Statement {
    enum Kind {
        case assignment(String, Expression)
        indirect case condition(Expression, Statement, Statement)
        indirect case block([Statement])
    }
    let kind: Kind, tokens: Range<Int>
}

public struct Expression {
    enum Kind {
        case number(Int)
        case identifier(String)
        indirect case calling(Expression, [Expression])
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
}

public enum ParseError: Error {
    case unexpectedToken(at: Token, expected: [ExpectedToken])
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
        guard case .dedent = source[offset].kind else {
            throw ParseError.unexpectedToken(
                at: source[offset], expected: [.dedent])
        }
        offset += 1
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
    guard case .assign = source[offset].kind else {
        throw ParseError.unexpectedToken(
            at: source[offset], expected: [.assign])
    }
    offset += 1
    let expr = try parseExpr(source, &offset)
    return Statement(kind: .assignment(name, expr), tokens: start..<offset)
}

func parseIfThenElse(
    _ source: [Token], _ offset: inout Int
) throws -> Statement {
    let start = offset
    guard case .if_ = source[offset].kind else {
        preconditionFailure()
    }
    offset += 1
    let cond = try parseExpr(source, &offset)
    guard case .then = source[offset].kind else {
        throw ParseError.unexpectedToken(
            at: source[offset], expected: [.then])
    }
    offset += 1
    let trueStat = try parseStat(source, &offset)
    guard case .else_ = source[offset].kind else {
        throw ParseError.unexpectedToken(
            at: source[offset], expected: [.else_])
    }
    offset += 1
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
    return try parseExprImpl(source, &offset, "$", parseExpr2)
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
        guard case .close = source[offset].kind else {
            throw ParseError.unexpectedToken(at: source[offset], expected: [.close])
        }
        offset += 1
        return expr
    default:
        throw ParseError.unexpectedToken(
            at: source[offset], expected: [.number, .identifier, .open])
    }
}
