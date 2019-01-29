//
//  Eval.swift
//  Flawed
//
//  Created by Cowsay on 2019/1/23.
//  Copyright (c) 2019 Cowsay. All rights reserved.
//

import Foundation


enum EvalError: Error {
    case isEnd
    case reassign(BindName)
    case invalidName(BindName)
}

public class Evaluator {
    public enum Module {
        case generated([Instruction])
        case native([String: (Evaluator) -> Void])
    }
    var modules: [String: Module]
    
    struct Context {
        var module: String
        var offset: Int
        var args: [BindName]
        var frames: [(module: String, offset: Int)]
        var mem: [BindName: Int]
        var refCount: [BindName: Int]
    }
    var context: Context
    
    public init(withMain module: Module) {
        modules = ["Main": module]
        context = Context(
            module: "Main", offset: 0, args: [], frames: [],
            mem: [:], refCount: [:])
    }
    
    func register(name: String, module: Module) {
        modules[name] = module
    }
    
    func executeOne() throws {
        let module = modules[context.module]!
        guard case .generated(let instList) = module else {
            preconditionFailure()
        }
        if context.offset == instList.count {
            throw EvalError.isEnd
        }
        let inst = instList[context.offset]
        context.offset += 1
        
        switch (inst) {
        case .constant(let name, let value):
            guard !context.mem.keys.contains(name) else {
                throw EvalError.reassign(name)
            }
            context.mem[name] = value
            context.refCount[name] = 1
        case .hold(let name, _):
            guard context.mem.keys.contains(name) else {
                throw EvalError.invalidName(name)
            }
            context.refCount[name]! += 1
        default:
            break
        }
    }
}
