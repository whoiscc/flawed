//
//  Eval.swift
//  Flawed
//
//  Created by Cowsay on 2019/1/23.
//  Copyright (c) 2019 Cowsay. All rights reserved.
//

import Foundation


public struct BindName {
    enum Kind {
        case anonymous(Int)
        case external(String, String)
    }
    
    let kind: Kind
    
    static var count = 0
    
    public static func alloc() -> BindName {
        let name = BindName(kind: .anonymous(count))
        count += 1
        return name
    }
}

extension BindName: CustomStringConvertible {
    public var description: String {
        switch (self.kind) {
        case .anonymous(let n):
            return "x\(n)"
        case .external(let module, let name):
            return "\(module):\(name)"
        }
    }
}

public class Evaluator {
    //
}

public enum Instruction {
    case constant(BindName, Int)
    case calling(BindName, BindName)
    case jumpIf(Int, BindName)
    case jump(Int)
    case jumpBack
    case arg([BindName])
    case unarg(BindName, Int)
    case hold(BindName, BindName), drop(BindName)
}

public enum EvalError: Error {
    case unresolved(String, Expression)
}

extension Instruction: CustomStringConvertible {
    public var description: String {
        switch (self) {
        case .constant(let name, let value):
            return "set \(name) \(value)"
        case .calling(let result, let function):
            return "\(result) <- call \(function)"
        case .jumpIf(let offset, let cond):
            return "\(cond) ?> \(offset)"
        case .jump(let offset):
            return "jump \(offset)"
        case .arg(let arguments):
            let argList = arguments.map { "\($0)" }.joined(separator: ", ")
            return "arg [\(argList)]"
        case .unarg(let name, let index):
            return "\(name) <- arg#\(index)"
        case .hold(let name, let root):
            return "\(root) hold \(name)"
        case .drop(let name):
            return "drop \(name)"
        case .jumpBack:
            return "back"
        }
    }
}

public class SymbolTable {
    var envList = [String: BindName]()
    var base: SymbolTable?
    
    init(_ base: SymbolTable) {
        self.base = base
    }
    
    public init(_ external: [String: BindName]) {
        envList = external
    }
    
    subscript(name: String) -> BindName? {
        get {
            if let bindName = envList[name] {
                return bindName
            }
            return base?[name]
        }
        set {
            envList[name] = newValue
        }
    }
}

public func generate(stat: Statement, env: SymbolTable)
    throws -> [Instruction]
{
    var inst = [Instruction](), env = env
    try genStat(stat, &env, &inst)
    return inst
}

func genStat(
    _ stat: Statement,
    _ env: inout SymbolTable,
    _ inst: inout [Instruction]
) throws {
    switch stat.kind {
    case .block(let seq):
        var subEnv = SymbolTable(env)
        for subStat in seq {
            try genStat(subStat, &subEnv, &inst)
        }
        for name in subEnv.envList.values {
            inst.append(.drop(name))
        }
    case .assignment(let name, let expr):
        let exprName = try genExpr(expr, env, &inst)
        env[name] = exprName
    case .condition(let expr, let trueStat, let falseStat):
        let exprName = try genExpr(expr, env, &inst)
        var trueInst = [Instruction](), falseInst = [Instruction]()
        try genStat(trueStat, &env, &trueInst)
        try genStat(falseStat, &env, &falseInst)
        inst.append(.jumpIf(falseInst.count + 1, exprName))
        inst.append(contentsOf: falseInst)
        inst.append(.jump(trueInst.count))
        inst.append(contentsOf: trueInst)
    }
}

func genExpr(
    _ expr: Expression,
    _ env: SymbolTable,
    _ inst: inout [Instruction]
) throws -> BindName {
    switch expr.kind {
    case .number(let value):
        let name = BindName.alloc()
        inst.append(.constant(name, value))
        return name
    case .identifier(let name):
        guard let bindName = env[name] else {
            throw EvalError.unresolved(name, expr)
        }
        return bindName
    case .calling(let function, let arguments):
        let resultName = BindName.alloc()
        let funcName = try genExpr(function, env, &inst)
        inst.append(.hold(funcName, resultName))
        var argNames = [BindName]()
        for arg in arguments {
            argNames.append(try genExpr(arg, env, &inst))
            inst.append(.hold(argNames.last!, resultName))
        }
        inst.append(.arg(argNames))
        inst.append(.calling(resultName, funcName))
        inst.append(.drop(funcName))
        for name in argNames {
            inst.append(.drop(name))
        }
        return resultName
    case .function(let arguments, let body):
        var funcInst = [Instruction]()
        var subEnv = SymbolTable(env)
        for (i, arg) in arguments.enumerated() {
            let bindName = BindName.alloc()
            funcInst.append(.unarg(bindName, i))
            subEnv[arg] = bindName
        }
        try genStat(body, &subEnv, &funcInst)
        funcInst.append(.jumpBack)
        
        let funcName = BindName.alloc()
        // 1 offset for this instruction itself, 1 offset for jump
        // TODO: add capture instructions
        inst.append(.constant(funcName, inst.count + 2))
        inst.append(.jump(funcInst.count))
        inst.append(contentsOf: funcInst)
        return funcName
    }
}
