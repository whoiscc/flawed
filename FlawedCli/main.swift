//
//  main.swift
//  FlawedCli
//
//  Created by Cowsay on 2019/1/29.
//  Copyright © 2019 Cowsay. All rights reserved.
//

import Foundation
import Flawed

let source = CommandLine.arguments[1]
let tokens = try scan(source: source)
let stat = try parse(tokens: tokens)
let instr = try generate(stat: stat, env: baseTable)
print(instr)
