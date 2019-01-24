//
//  Grammar.swift
//  Flawed
//
//  Created by Cowsay on 2019/1/17.
//  Copyright (c) 2019 Cowsay. All rights reserved.
//

import Foundation


// program : stat `\n` program | stat `\n` | stat
// stat : assign
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
    // TODO
    default:
        throw ParseError.unexpectedToken(
            at: source[offset], expected: [.identifier])
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

func parseExpr(
    _ source: [Token], _ offset: inout Int
) throws -> Expression {
    let start = offset
    let left = try parseExpr2(source, &offset)
    switch (source[offset].kind) {
    case .operator_(let op) where "+-".contains(op.first!):
        let opPos = offset
        offset += 1
        let right = try parseExpr(source, &offset)
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

func parseExpr2(
    _ source: [Token], _ offset: inout Int
) throws -> Expression {
    let start = offset
    let left = try parseExpr3(source, &offset)
    switch (source[offset].kind) {
    case .operator_(let op) where "*/".contains(op.first!):
        let opPos = offset
        offset += 1
        let right = try parseExpr(source, &offset)
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

func parseExpr3(
    _ source: [Token], _ offset: inout Int
) throws -> Expression {
    let start = offset
    if case .operator_(let op) = source[offset].kind {
        offset += 1
        let expr = try parseExpr4(source, &offset)
        return Expression(
            kind: .calling(
                Expression(kind: .identifier(op), tokens: start..<start + 1),
                [expr]
            ),
            tokens: start..<offset
        )
    } else {
        return try parseExpr4(source, &offset)
    }
}

func parseExpr4(
    _ source: [Token], _ offset: inout Int
) throws -> Expression {
    let start = offset
    let firstFunc = try parseExpr5(source, &offset)
    if case .open = source[offset].kind {
        let callingList = try parseExpr4_(source, &offset)
        var expr = firstFunc
        for argList in callingList {
            expr = Expression(kind: .calling(expr, argList), tokens: start..<offset)
        }
        return expr
    } else {
        return firstFunc
    }
}

func parseExpr4_(
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

func parseExpr5(
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
