//
//  Token.swift
//  Flawed
//
//  Created by Cowsay on 2019/1/19.
//  Copyright (c) 2019 Cowsay. All rights reserved.
//

import Foundation


public enum Token {
    case number(Int)
    case identifier(String)
    case open, close
    case assign
    case comma
    case operator_(String)
    case newline
    case end
}

public enum ScanError: Error {
    case unknownCharacter(Character)
    case unpairedClose
}

public func scan(source: String) throws -> [Token] {
    var pos = source.startIndex
    var tokens = [Token]()
    
    var openLevel = 0
    while pos < source.endIndex {
        switch source[pos] {
        case ";":
            while pos < source.endIndex && source[pos] != "\n" {
                pos = source.index(after: pos)
            }
        case "\n":
            if !tokens.isEmpty && openLevel == 0 {
                if case .newline = tokens.last! {} else {
                    tokens.append(.newline)
                }
            }
            pos = source.index(after: pos)
        case "(":
            tokens.append(.open)
            openLevel += 1
            pos = source.index(after: pos)
        case ")":
            if openLevel == 0 {
                throw ScanError.unpairedClose
            }
            tokens.append(.close)
            openLevel -= 1
            pos = source.index(after: pos)
        case ",":
            tokens.append(.comma)
            pos = source.index(after: pos)
        case "a"..."z", "A"..."Z", "_":
            let endPos = scanName(source, pos)
            tokens.append(.identifier(String(source[pos..<endPos])))
            pos = endPos
        case "0"..."9":
            var num = 0
            while pos != source.endIndex && ("0"..."9").contains(source[pos]) {
                num = num * 10 + Int(String(source[pos]))!
                pos = source.index(after: pos)
            }
            tokens.append(.number(num))
        case "!", "@", "#", "$", "%", "^", "&", "*", "-", "+", "=",
             ":", "|", "<", ">", ".", "/", "?", "\\":
            let endPos = scanName(source, pos)
            if source[pos..<endPos] == "<-" {
                tokens.append(.assign)
            } else {
                tokens.append(.operator_(String(source[pos..<endPos])))
            }
            pos = endPos
        case " ":
            pos = source.index(after: pos)
        default:
            throw ScanError.unknownCharacter(source[pos])
        }
    }
    tokens.append(.end)
    return tokens
}

func scanName(_ source: String, _ start: String.Index) -> String.Index {
    var pos = start
    while pos != source.endIndex && !" \n(),".contains(source[pos]) {
        pos = source.index(after: pos)
    }
    return pos
}
