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
        case indent, dedent
        case assign
        case comma
        case operator_(String)
        case newline
        case end
        case if_, then, else_
    }
    let kind: Kind
    let beginLine, beginColumn, endLine, endColumn: Int
}

public struct ScanError: Error {
    let line, column: Int
    enum Kind {
        case unknownCharacter(Character)
        case unpairedClose
        case unmatchIndent(Int)
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

struct NewlineManager {
    var openLevel = 0
    var afterIf = false
    var indentLevel = [0]
    
    mutating func process(
        _ source: inout Source, _ tokens: inout [Token]
    ) throws {
        let line = source.line, column = source.column
        source.forward()  // for '\n'
        var spaceCount = 0
        while !source.isEnd && source.current == " " {
            spaceCount += 1
            source.forward()
        }
        
        // ignore trailing whitespaces
        if source.isEnd || source.current == "\n" {
            return
        }
        
        // ignore newline between .open and .close
        if openLevel != 0 {
            return
        }
        
        // insert .then for if-then-else
        if afterIf {
            afterIf = false
            tokens.append(Token(
                kind: .then,
                beginLine: line, beginColumn: column,
                endLine: line, endColumn: column + 1))
        }
        
        if indentLevel.last! < spaceCount {
            tokens.append(Token(
                kind: .indent,
                beginLine: source.line, beginColumn: 1,
                endLine: source.line, endColumn: source.column))
            indentLevel.append(spaceCount)
        } else if indentLevel.last! > spaceCount {
            guard let match = indentLevel.firstIndex(of: spaceCount) else {
                throw ScanError(
                    line: source.line, column: source.column,
                    kind: .unmatchIndent(spaceCount))
            }
            let oldLength = indentLevel.count
            for _ in match + 1 ..< oldLength {
                tokens.append(Token(
                    kind: .dedent,
                    beginLine: source.line, beginColumn: 1,
                    endLine: source.line, endColumn: source.column))
                let _ = indentLevel.popLast()
            }
        } else {
            tokens.append(Token(
                kind: .newline,
                beginLine: line, beginColumn: column,
                endLine: source.line, endColumn: source.column))
        }
    }
}

public func scan(source content: String) throws -> [Token] {
    var source = Source(content), manager = NewlineManager()
    var tokens = [Token]()
    
    while !source.isEnd {
        let line = source.line, column = source.column
        switch source.current {
        case ";":
            while !source.isEnd && source.current != "\n" {
                source.forward()
            }
        case "\n":
            try manager.process(&source, &tokens)
        case "(":
            tokens.append(source.forwardToken(.open))
            manager.openLevel += 1
        case ")":
            if manager.openLevel == 0 {
                throw ScanError(line: line, column: column, kind: .unpairedClose)
            }
            tokens.append(source.forwardToken(.close))
            manager.openLevel -= 1
        case ",":
            tokens.append(source.forwardToken(.comma))
        case "a"..."z", "A"..."Z", "_":
            let name = source.scanName()
            var kind: Token.Kind!
            if name == "if" {
                kind = .if_
                manager.afterIf = true
            } else if name == "else" {
                kind = .else_
            } else {
                kind = .identifier(name)
            }
            tokens.append(Token(
                kind: kind,
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
    for level in manager.indentLevel {
        if level == 0 {
            continue
        }
        tokens.append(Token(
            kind: .dedent,
            beginLine: source.line, beginColumn: source.column,
            endLine: source.line, endColumn: source.column + 1
        ))
    }
    tokens.append(Token(
        kind: .end,
        beginLine: source.line, beginColumn: source.column,
        endLine: source.line, endColumn: source.column + 1
    ))
    return tokens
}
