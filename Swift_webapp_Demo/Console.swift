//
//  Console.swift
//  Swift_webapp_Demo
//
//  Created by XUHUI on 15/9/16.
//  Copyright © 2015年 XUHUI. All rights reserved.
//

import Foundation

class Console: Plugin {
    func log() {
        if let string = self.data {
            NSLog("jscallnative >>> " + string)
        }
    }
}