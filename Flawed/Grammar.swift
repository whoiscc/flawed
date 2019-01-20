//
//  Grammar.swift
//  Flawed
//
//  Created by Cowsay on 2019/1/17.
//  Copyright (c) 2019 Cowsay. All rights reserved.
//

import Foundation


// program : stat `\n` program | stat
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
enum LangNode {
    enum Statement {
        case assignment(String, Expression)
        indirect case condition(Expression, Statement, Statement)
        indirect case block([Statement])
    }
    enum Expression {
        case number(Int)
        case identifier(String)
        indirect case calling(Expression, [Expression])
    }
}

enum Token {
    case number(Int)
    case identifier(String)
    case open, close
    case assign
    case comma
    case operator_(String)
    case newline
    case end
}

enum ParseError: Error {
    case unexpectedToken(at: Int, expected: [Token])
}

func parse(source: [Token]) throws -> LangNode.Statement {
    var _offset = 0
    let node = try parseProgram(source, &_offset)
    return node
}

func parseProgram(
    _ source: [Token], _ offset: inout Int
) throws -> LangNode.Statement {
    var statements = [LangNode.Statement]()
    while true {
        if case .end = source[offset] {
            break
        }
        let stat = try parseStat(source, &offset)
        statements.append(stat)
        if case .newline = source[offset] {
            offset += 1
        }
    }
    return .block(statements)
}

func parseStat(
    _ source: [Token], _ offset: inout Int
) throws -> LangNode.Statement {
    switch source[offset] {
    case .identifier:
        return try parseAssign(source, &offset)
    // TODO
    default:
        throw ParseError.unexpectedToken(
            at: offset, expected: [.identifier("<any>")])
    }
}

func parseAssign(
    _ source: [Token], _ offset: inout Int
) throws -> LangNode.Statement {
    guard case .identifier(let name) = source[offset] else {
        preconditionFailure()
    }
    offset += 1
    guard case .assign = source[offset] else {
        throw ParseError.unexpectedToken(
            at: offset, expected: [.assign])
    }
    offset += 1
    let expr = try parseExpr(source, &offset)
    return .assignment(name, expr)
}

func parseExpr(
    _ source: [Token], _ offset: inout Int
) throws -> LangNode.Expression {
    let left = try parseExpr2(source, &offset)
    switch (source[offset]) {
    case .operator_(let op) where "+-".contains(op.first!):
        offset += 1
        let right = try parseExpr(source, &offset)
        return .calling(.identifier(op), [left, right])
    default:
        return left
    }
}

func parseExpr2(
    _ source: [Token], _ offset: inout Int
) throws -> LangNode.Expression {
    let left = try parseExpr3(source, &offset)
    switch (source[offset]) {
    case .operator_(let op) where "*/".contains(op.first!):
        offset += 1
        let right = try parseExpr2(source, &offset)
        return .calling(.identifier(op), [left, right])
    default:
        return left
    }
}

func parseExpr3(
    _ source: [Token], _ offset: inout Int
) throws -> LangNode.Expression {
    if case .operator_(let op) = source[offset] {
        offset += 1
        let expr = try parseExpr4(source, &offset)
        return .calling(.identifier(op), [expr])
    } else {
        return try parseExpr4(source, &offset)
    }
}

func parseExpr4(
    _ source: [Token], _ offset: inout Int
) throws -> LangNode.Expression {
    let firstFunc = try parseExpr5(source, &offset)
    if case .open = source[offset] {
        let callingList = try parseExpr4_(source, &offset)
        var expr = firstFunc
        for argList in callingList {
            expr = .calling(expr, argList)
        }
        return expr
    } else {
        return firstFunc
    }
}

func parseExpr4_(
    _ source: [Token], _ offset: inout Int
) throws -> [[LangNode.Expression]] {
    var callingList = [[LangNode.Expression]]()
    while case .open = source[offset] {
        offset += 1
        var argList = [LangNode.Expression]()
        while true {
            if case .close = source[offset] {
                offset += 1
                break
            }
            let expr = try parseExpr(source, &offset)
            argList.append(expr)
            if case .comma = source[offset] {
                offset += 1
            }
        }
        callingList.append(argList)
    }
    return callingList
}

func parseExpr5(
    _ source: [Token], _ offset: inout Int
) throws -> LangNode.Expression {
    switch (source[offset]) {
    case .number(let num):
        offset += 1
        return .number(num)
    case .identifier(let id):
        offset += 1
        return .identifier(id)
    default:
        throw ParseError.unexpectedToken(
            at: offset, expected: [.number(0), .identifier("<any>")])
    }
}
