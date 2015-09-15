//
//  ViewController.swift
//  Swift_webapp_Demo
//
//  Created by XUHUI on 15/9/14.
//  Copyright (c) 2015年 XUHUI. All rights reserved.
//

import WebKit
import UIKit

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {

    var wk: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let conf = WKWebViewConfiguration()
        conf.userContentController.addScriptMessageHandler(self, name: "jscallnative")
        
        self.wk = WKWebView(frame: self.view.frame, configuration: conf)
        self.wk.navigationDelegate = self
        self.wk.UIDelegate = self
        self.wk.loadRequest(NSURLRequest(URL: NSURL(string: "http://www.baidu.com/")!))
        
        self.runPluginJS(["Base", "Console", "Accelerometer"])
        self.view.addSubview(self.wk)
    }
    
    func runPluginJS(names: Array<String>) {
        for name in names {
            if let path = NSBundle.mainBundle().pathForResource(name, ofType: "js", inDirectory: "www/plugins") {
                do {
                    let js = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)
                    self.wk.evaluateJavaScript(js as String, completionHandler: nil)
                } catch let error as NSError {
                    NSLog(error.debugDescription)
                }
            }
        }
    }


}

private typealias wkNavigationDelegate = ViewController
extension wkNavigationDelegate {
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        NSLog(error.debugDescription)
    }
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        NSLog(error.debugDescription)
    }
}

private typealias wkUIDelegate = ViewController
extension wkUIDelegate {
    func webView(webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: () -> Void) {
        let ac = UIAlertController(title: webView.title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        ac.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (aa) -> Void in
            completionHandler()
        }))
        self.presentViewController(ac, animated: true, completion: nil)
    }
}

private typealias wkScriptMessageHandler = ViewController
extension wkScriptMessageHandler {
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if message.name == "jscallnative" {
            if let dic = message.body as? NSDictionary,
                className = dic["className"]?.description,
                functionName = dic["functionName"]?.description {
                    if let cls = NSClassFromString(NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName")!.description + "." + className) as? Plugin.Type{
                        let obj = cls.init()
                        obj.wk = self.wk
                        obj.taskId = dic["taskId"]?.integerValue
                        obj.data = dic["data"]?.description
                        let functionSelector = Selector(functionName)
                        if obj.respondsToSelector(functionSelector) {
                            obj.performSelector(functionSelector)
                        } else {
                            print("方法未找到！", terminator: "")
                        }
                    } else {
                        print("类未找到！", terminator: "")
                    }
            }
        }
    }
}


class Plugin: NSObject {
    var wk: WKWebView!
    var taskId: Int!
    var data: String?
    required override init() {
    }
    func callback(values: NSDictionary) -> Bool {
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(values, options: NSJSONWritingOptions())
            if let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding) as? String {
                let js = "fireTask(\(self.taskId), '\(jsonString)');"
                self.wk.evaluateJavaScript(js, completionHandler: nil)
                return true
            }
        } catch let error as NSError{
            NSLog(error.debugDescription)
            return false
        }
        return false
    }
    func errorCallback(errorMessage: String) {
        let js = "onError(\(self.taskId), '\(errorMessage)');"
        self.wk.evaluateJavaScript(js, completionHandler: nil)
    }
}

