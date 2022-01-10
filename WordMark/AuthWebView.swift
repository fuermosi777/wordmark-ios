//
//  AuthWebView.swift
//  WordMark
//
//  Created by Hao Liu on 1/10/21.
//

import SwiftUI
import WebKit

struct AuthWebView: UIViewRepresentable {
  let defaultURL: URL
  
  @Binding var code: String?
  
  class Coordinator: NSObject, WKNavigationDelegate {
    let embedded: AuthWebView
    
    init(_ embedded: AuthWebView) {
      self.embedded = embedded
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
      if let url = navigationAction.request.url {
        if let host = url.host {
          if host.contains("wordmarkapp.com") {
            embedded.code = url.query("code")
          }
        }
      }
      
      decisionHandler(.allow)
    }
  }
  
  func makeCoordinator() -> AuthWebView.Coordinator {
    Coordinator(self)
  }
  
  func makeUIView(context: Context) ->WKWebView {
    
    let webview = WKWebView()
    
    // TODO: remove cookie first.
    let request = URLRequest(url: defaultURL)
    webview.navigationDelegate = context.coordinator
    webview.load(request)
    return webview
  }
  
  func updateUIView(_ uiView: WKWebView, context: Context) {}
  
}
