//
//  Token.swift
//  Flawed
//
//  Created by Cowsay on 2019/1/19.
//  Copyright (c) 2019 Cowsay. All rights reserved.
//

import Foundation


public struct Token {
    enum Kind {
        case number(Int)
        case identifier(String)
        case open, close
        case assign
        case comma
        case operator_(String)
        case newline
        case end
    }
    let kind: Kind
    let beginLine, beginColumn, endLine, endColumn: Int
}

public struct ScanError: Error {
    let line, column: Int
    enum Kind {
        case unknownCharacter(Character)
        case unpairedClose
    }
    let kind: Kind
}

struct Source {
    let content: String
    var line = 1, column = 1
    var pos: String.Index
    
    init(_ content: String) {
        self.content = content
        pos = self.content.startIndex
    }
    
    mutating func forward() {
        if content[pos] == "\n" {
            line += 1
            column = 1
        } else {
            column += 1
        }
        pos = content.index(after: pos)
    }
    
    mutating func forwardToken(_ kind: Token.Kind) -> Token {
        let line = self.line, column = self.column
        forward()
        return Token(
            kind: kind,
            beginLine: line, beginColumn: column,
            endLine: self.line, endColumn: self.column
        )
    }
    
    var isEnd: Bool {
        return pos == content.endIndex
    }
    
    var current: Character {
        return content[pos]
    }
    
    mutating func scanName() -> String {
        let start = pos
        while !isEnd && !" \n(),".contains(current) {
            forward()
        }
        return String(content[start..<pos])
    }
}

public func scan(source content: String) throws -> [Token] {
    var source = Source(content)
    var tokens = [Token]()
    
    var openLevel = 0
    while !source.isEnd {
        let line = source.line, column = source.column
        switch source.current {
        case ";":
            while !source.isEnd && source.current != "\n" {
                source.forward()
            }
        case "\n":
            if !tokens.isEmpty && openLevel == 0 {
                if case .newline = tokens.last!.kind {
                    source.forward()
                } else {
                    tokens.append(source.forwardToken(.newline))
                }
            } else {
                source.forward()
            }
        case "(":
            tokens.append(source.forwardToken(.open))
            openLevel += 1
        case ")":
            if openLevel == 0 {
                throw ScanError(line: line, column: column, kind: .unpairedClose)
            }
            tokens.append(source.forwardToken(.close))
            openLevel -= 1
        case ",":
            tokens.append(source.forwardToken(.comma))
        case "a"..."z", "A"..."Z", "_":
            let name = source.scanName()
            tokens.append(Token(
                kind: .identifier(name),
                beginLine: line, beginColumn: column,
                endLine: source.line, endColumn: source.column
            ))
        case "0"..."9":
            var num = 0
            while !source.isEnd && ("0"..."9").contains(source.current) {
                num = num * 10 + Int(String(source.current))!
                source.forward()
            }
            tokens.append(Token(
                kind: .number(num),
                beginLine: line, beginColumn: column,
                endLine: source.line, endColumn: source.column
            ))
        case "!", "@", "#", "$", "%", "^", "&", "*", "-", "+", "=",
             ":", "|", "<", ">", ".", "/", "?", "\\":
            let name = source.scanName()
            let kind: Token.Kind = name == "<-" ? .assign : .operator_(name)
            tokens.append(Token(
                kind: kind,
                beginLine: line, beginColumn: column,
                endLine: source.line, endColumn: source.column
            ))
        case " ":
            source.forward()
        default:
            throw ScanError(
                line: line, column: column,
                kind: .unknownCharacter(source.current))
        }
    }
    tokens.append(Token(
        kind: .end,
        beginLine: source.line, beginColumn: source.column,
        endLine: source.line, endColumn: source.column + 1
    ))
    return tokens
}
