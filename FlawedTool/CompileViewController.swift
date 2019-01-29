//
//  ViewController.swift
//  FlawedTool
//
//  Created by Cowsay on 2019/1/20.
//  Copyright © 2019 Cowsay. All rights reserved.
//

import Cocoa
import Flawed

enum CompiledSource {
    case success([Instruction])
    case failure(Error)
    case empty
}

class CompileViewController: NSViewController, NSTextDelegate, NSWindowDelegate {

    @IBOutlet var input: NSTextView!
    @IBOutlet var output: NSTextView!
    
    @IBOutlet weak var outputTopMargin: NSLayoutConstraint!
    let font: NSFont! = NSFont(name: "Fira Mono", size: 12)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        output.font = font
        input.font = font
        
        representedObject = CompiledSource.empty
        outputTopMargin.constant = view.frame.height * 0.6
    }
    
    override func viewDidAppear() {
        view.window!.delegate = self
    }

    override var representedObject: Any? {
        didSet {
            switch (representedObject as! CompiledSource) {
            case .empty:
                output.string = "Input your program above."
                output.textColor = NSColor.gray
            case .success(let node):
                output.string = "\(node)"
                output.textColor = NSColor.blue
            case .failure(let error):
                output.string = "\(error)"
                output.textColor = NSColor.red
            }
        }
    }

    @IBAction func onCompile(_ sender: Any) {
//        NSLog("compile")
        let source = input.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else {
            representedObject = CompiledSource.empty
            return
        }
        do {
            let node = try parse(tokens: try scan(source: source))
            let inst = try generate(stat: node, env: baseTable)
            representedObject = CompiledSource.success(inst)
        } catch {
            representedObject = CompiledSource.failure(error)
        }
        NSAnimationContext.runAnimationGroup { (context) in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(
                name: CAMediaTimingFunctionName.easeInEaseOut)
            outputTopMargin.animator().constant = view.frame.height * 0.3
        }
    }
    
    func textDidChange(_ notification: Notification) {
//        NSLog("changed")
        NSAnimationContext.runAnimationGroup { (context) in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            outputTopMargin.animator().constant = view.frame.height * 0.6
        }
    }
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        NSLog("\(frameSize)")
        NSAnimationContext.runAnimationGroup { (context) in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            outputTopMargin.animator().constant = frameSize.height * 0.6
        }
        return frameSize
    }
}
