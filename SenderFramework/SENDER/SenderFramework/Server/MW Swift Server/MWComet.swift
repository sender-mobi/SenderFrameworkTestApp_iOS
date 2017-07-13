//
//  MWComet.swift
//  SENDER
//
//  Created by Eugene Gilko on 4/4/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import Foundation

class MWComet: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    
    var ch : (() -> ())!
    
    var tmpRequest: URLRequest?
    let MWConnectionCoordinator = MWConnectionsCoordinator()
    
    func getBackgroundSession() -> Foundation.URLSession {
      
        return Foundation.URLSession()// RequestBuilder.shared.backCometSession
    }
    
    func startDownload (_ request:URLRequest?) {
        
        let task = self.getBackgroundSession().downloadTask(with: request!)
        task.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let prog = Double(totalBytesWritten)/Double(totalBytesExpectedToWrite)
        NSLog("%@", "downloaded \(100.0 * prog)%")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "GotProgress"), object:self, userInfo:["progress":prog])
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let data = try? Data(contentsOf: location) else {return}
        
        do {
            
//            let result = self.tryToDecodeReceivedData(taskItem!.storedTaskData!)
//            
//            if result.count > 0 {
//                
//                let resCode = result["code"]
//                
//                switch resCode! as! Int {
//                case 0:
//                    print(result)
//                    break
//                default:
//                    break
//                
//                }
//            }
            
            
            if let rez = try JSONSerialization.jsonObject(with: data, options:[]) as? [String: AnyObject] {
                
                print("+++++++++++++++++++++++++++++++++\n=======================================\n+++++++++++++++++++++++++++++++++\n")
                
                let valid = MWConnectionCoordinator.validateServerResponse(rez as NSDictionary?)
                
                if valid {
                    print("RESULT CODE OK")
                }
                else {
                    print("RESULT CODE FAIL with CODE = \(rez["code"])")
                }
                
                print(rez)
            }
        } catch  {}
        
        DispatchQueue.main.async {
            NSLog("%@", "finished")
            
//            self.startDownload(self.tmpRequest!)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        NSLog("%@", "completed; error: \(error)")
    }
    
//    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
//        NSLog("%@", "hello hello, storing completion handler")
//        self.ch = completionHandler
//        let _ = self.session // make sure we have one
//    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        
        NSLog("%@", "calling completion handler")
        if self.ch != nil {
            self.ch()
        }
    }

    fileprivate func tryToDecodeReceivedData(_ data: Data) -> NSDictionary {
        
        do {
            if let rez = try JSONSerialization.jsonObject(with: data, options:[]) as? [String: AnyObject] {
                return rez as NSDictionary
            }
        } catch  {
        }
        
        return NSDictionary()
    }
}
