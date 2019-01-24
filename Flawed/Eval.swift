//
//  Eval.swift
//  Flawed
//
//  Created by Cowsay on 2019/1/23.
//  Copyright (c) 2019 Cowsay. All rights reserved.
//

import Foundation


public struct BindName {
    let index: Int
    
    static var count = 0
    
    public static func alloc() -> BindName {
        let name = BindName(index: count)
        count += 1
        return name
    }
}

public enum Instruction {
    case constant(BindName, Int)
    case calling(BindName, BindName, [BindName])
    case jumpIf(Int, BindName)
    case jump(Int)
}

public enum EvalError: Error {
    case unresolved(String)
}

extension Instruction: CustomStringConvertible {
    public var description: String {
        switch (self) {
        case .constant(let name, let value):
            return "x\(name.index) <- \(value)"
        case .calling(let result, let function, let arguments):
            let argList = arguments.map { "x\($0.index)" }.joined(separator: ", ")
            return "x\(result.index) <- x\(function.index)(\(argList))"
        case .jumpIf(let offset, let cond):
            return "x\(cond.index) ? => \(offset)"
        case .jump(let offset):
            return "=> \(offset)"
        }
    }
}

public func eval(stat: LangNode.Statement, env: [String: BindName])
    throws -> [Instruction]
{
    var inst = [Instruction](), env = env
    try evalStat(stat, &env, &inst)
    return inst
}

func evalStat(
    _ stat: LangNode.Statement,
    _ env: inout [String: BindName],
    _ inst: inout [Instruction]
) throws {
    switch stat {
    case .block(let seq):
        for subStat in seq {
            try evalStat(subStat, &env, &inst)
        }
    case .assignment(let name, let expr):
        let exprName = try evalExpr(expr, env, &inst)
        env[name] = exprName
    case .condition(let expr, let trueStat, let falseStat):
        let exprName = try evalExpr(expr, env, &inst)
        var trueInst = [Instruction](), falseInst = [Instruction]()
        try evalStat(trueStat, &env, &trueInst)
        try evalStat(falseStat, &env, &falseInst)
        inst.append(.jumpIf(falseInst.count + 1, exprName))
        inst.append(contentsOf: falseInst)
        inst.append(.jump(trueInst.count))
        inst.append(contentsOf: trueInst)
    }
}

func evalExpr(
    _ expr: LangNode.Expression,
    _ env: [String: BindName],
    _ inst: inout [Instruction]
) throws -> BindName {
    switch expr {
    case .number(let value):
        let name = BindName.alloc()
        inst.append(.constant(name, value))
        return name
    case .identifier(let name):
        guard let bindName = env[name] else {
            throw EvalError.unresolved(name)
        }
        return bindName
    case .calling(let function, let arguments):
        let funcName = try evalExpr(function, env, &inst)
        var argNames = [BindName]()
        for arg in arguments {
            argNames.append(try evalExpr(arg, env, &inst))
        }
        let resultName = BindName.alloc()
        inst.append(.calling(resultName, funcName, argNames))
        return resultName
    }
}
