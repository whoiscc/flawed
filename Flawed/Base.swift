//
//  Base.swift
//  Flawed
//
//  Created by Cowsay on 2019/1/26.
//  Copyright (c) 2019 Cowsay. All rights reserved.
//

import Foundation


func add(env: Evaluator) -> Void {
    //
}

public let baseModule: Evaluator.Module = .native([
    "Add": add
])

public let baseTable = SymbolTable([
    "+": BindName.external(module: "Base", name: "Add"),
    "-": BindName.external(module: "Base", name: "Sub"),
    "*": BindName.external(module: "Base", name: "Mul"),
    "/": BindName.external(module: "Base", name: "Div"),
    "abs": BindName.external(module: "Base", name: "Abs")
])
