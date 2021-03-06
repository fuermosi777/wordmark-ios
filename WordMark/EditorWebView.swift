//
//  EditorWebView.swift
//  WordMark
//
//  Created by Hao Liu on 8/28/21.
//

import SwiftUI
import WebKit

let kCodeMirrorFileName = "index"

class CMEditorWebView: WKWebView {
  var acccessoryView: UIView?
  
  override var inputAccessoryView: UIView? {
    let bar = UIToolbar()
    bar.frame = CGRect(x: 0, y: 50, width: 320, height: 44)
    bar.barStyle = .default
    // Other options:
    //    bar.tintColor = .white
    //    bar.barTintColor = .lightGray
    
    let bold = UIBarButtonItem(image: UIImage(systemName: "bold"), style: .plain, target: self, action: #selector(self.insertBold(sender:)))
    let italic = UIBarButtonItem(image: UIImage(systemName: "italic"), style: .plain, target: self, action: #selector(self.insertItalic(sender:)))
    let heading = UIBarButtonItem(image: UIImage(systemName: "number"), style: .plain, target: self, action: #selector(self.insertHeading(sender:)))
    let hr = UIBarButtonItem(image: UIImage(systemName: "trapezoid.and.line.horizontal"), style: .plain, target: self, action: #selector(self.insertHr(sender:)))
    let link = UIBarButtonItem(image: UIImage(systemName: "link"), style: .plain, target: self, action: #selector(self.insertLink(sender:)))
    let image = UIBarButtonItem(image: UIImage(systemName: "photo"), style: .plain, target: self, action: #selector(self.insertImage(sender:)))
    let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let keyboard = UIBarButtonItem(image: UIImage(systemName: "keyboard.chevron.compact.down"), style: .plain, target: self, action: #selector(self.dismissKeyboard(sender:)))
    
    bar.items = [heading, bold, italic, link, image, hr, spacer]
    
    if UIDevice.current.userInterfaceIdiom == .phone {
      bar.items?.append(keyboard)
    }
    
    bar.isUserInteractionEnabled = true
//    bar.sizeToFit()
    return bar
  }
  
  @objc func insertBold(sender: Any) {
    self.evaluateJavaScript("ClientInsert('****', 2);",
                             completionHandler: nil);
  }
  
  @objc func insertItalic(sender: Any) {
    self.evaluateJavaScript("ClientInsert('**', 1);",
                             completionHandler: nil);
  }
  
  @objc func insertHeading(sender: Any) {
    self.evaluateJavaScript("ClientInsert('#');",
                             completionHandler: nil);
  }
  
  @objc func insertHr(sender: Any) {
    self.evaluateJavaScript("ClientInsert('---');",
                             completionHandler: nil);
  }
  
  @objc func insertLink(sender: Any) {
    self.evaluateJavaScript("ClientInsert('[]()', 3);",
                             completionHandler: nil);
  }
  
  @objc func insertImage(sender: Any) {
    self.evaluateJavaScript("ClientInsert('![]()', 3);",
                             completionHandler: nil);
  }
  
  @objc func dismissKeyboard(sender: Any) {
    self.endEditing(true)
  }
}

struct EditorWebView: UIViewRepresentable {
  @Binding var content: String
  
  @AppStorage("editorFontSize") private var editorFontSize = 16.0
  @AppStorage("styleActiveLine") private var styleActiveLine = false
  @AppStorage("regularFontFamily") private var regularFontFamily = Font.Default.rawValue
  
  init(content: Binding<String>) {
    _content = content
  }
  
  class Coordinator: NSObject {
    let embedded: EditorWebView
    
    var editorFontSize: Double
    var regularFontFamily: Int
    var styleActiveLine: Bool
    
    init(_ embedded: EditorWebView) {
      self.embedded = embedded
      
      editorFontSize = embedded.editorFontSize
      regularFontFamily = embedded.regularFontFamily
      styleActiveLine = embedded.styleActiveLine
    }
  }
  
  
  class MessageHandler: NSObject, WKScriptMessageHandler {
    @Environment(\.openURL) var openURL
    
    let embedded: EditorWebView
    let uiView: CMEditorWebView
    var debouncer: Timer?
    
    init(_ embedded: EditorWebView, _ uiView: CMEditorWebView) {
      self.embedded = embedded
      self.uiView = uiView
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
      if message.name == "Loaded" {
        let scriptToUpdateDoc = "ClientInitEditor(`\(embedded.content.toBase64())`);ClientToggleActiveLine(\(embedded.styleActiveLine));ClientUpdateFontSize(\(embedded.editorFontSize));"
        self.uiView.evaluateJavaScript(scriptToUpdateDoc, completionHandler: nil);
        
        if let font = Font.init(rawValue: embedded.regularFontFamily) {
          self.uiView.evaluateJavaScript("ClientUpdateFont('\(font.familyName)')", completionHandler: nil);
        }
      } else if message.name == "DocChanged" {
        if message.body is String {
          // Update embedded webview's content.
          // We need to deboucne it because otherwise there will be memory leak for unknown reason.
          debouncer?.invalidate()
          debouncer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            self.embedded.content = message.body as! String
          }
        }
      } else if message.name == "RequestURL" {
        if message.body is String {
          openURL(URL(string: message.body as! String)!)
        }
      }
    }
  }
  
  func makeCoordinator() -> EditorWebView.Coordinator {
    Coordinator(self)
  }
  
  
  func makeUIView(context: Context) -> WKWebView {
    guard let fileURL = Bundle.main.url(forResource: kCodeMirrorFileName,
                                        withExtension: "html") else {
      return CMEditorWebView()
    }
    
    let webview = CMEditorWebView()
    webview.loadFileURL(fileURL, allowingReadAccessTo: fileURL)
    webview.allowsLinkPreview = false
    
    // A workaround to fix webview scrolling issue when keyboard appears.
    // https://rick38yip.medium.com/wkwebview-weird-spacing-issue-in-ios-13-54a4fc686f72
    webview.scrollView.contentInsetAdjustmentBehavior = .never
    
    // Register communication event names.
    webview.configuration.userContentController.add(MessageHandler(self, webview), name: "Loaded")
    webview.configuration.userContentController.add(MessageHandler(self, webview), name: "DocChanged")
    webview.configuration.userContentController.add(MessageHandler(self, webview), name: "RequestURL")
    
    // Delete cookies so that users can login with different accounts.
    HTTPCookieStorage.shared.cookies?.forEach(HTTPCookieStorage.shared.deleteCookie)
    return webview
  }
  
  
  func updateUIView(_ uiView: WKWebView, context: Context) {
    if context.coordinator.editorFontSize != editorFontSize {
      uiView.evaluateJavaScript("ClientUpdateFontSize(\(editorFontSize));",
                                completionHandler: nil);
      context.coordinator.editorFontSize = editorFontSize
    }
    
    if context.coordinator.styleActiveLine != styleActiveLine {
      uiView.evaluateJavaScript("ClientToggleActiveLine(\(styleActiveLine));",
                                completionHandler: nil);
      context.coordinator.styleActiveLine = styleActiveLine
    }
    
    if context.coordinator.regularFontFamily != regularFontFamily {
      guard let font = Font.init(rawValue: regularFontFamily) else { return }
      uiView.evaluateJavaScript("ClientUpdateFont('\(font.familyName)');",
                                completionHandler: nil);
      context.coordinator.regularFontFamily = regularFontFamily
    }
  }
}
