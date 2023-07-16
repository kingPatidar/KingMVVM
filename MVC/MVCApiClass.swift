//
//  MVCApiClass.swift
//  MVVM+MVCKingClass
//
//  Created by MacBook on 16/07/23.
//

import UIKit
import Alamofire

private var sharedApi:ApiMVCHandlerClass? = nil

class ApiMVCHandlerClass: NSObject {
    
    class func shared() -> ApiMVCHandlerClass
    {
        if sharedApi == nil
        {
            sharedApi = ApiMVCHandlerClass()
        }
        return sharedApi!
    }
    
    func apiCall(methodName:APIMethod, apiName:String?, body:NSMutableDictionary,imageBody:NSMutableArray, passUserInfoInHeader : Bool, isShowActivityIndicator : Bool, contentType : String,url : String, parameterEncoding:ParameterEncoding, completionhandler: @escaping(NSDictionary?, String?) -> Void)
    {
        if Reachability().connectionStatus().isOnline()
        {
            guard let urlStr = apiName,
                  let url = URL.init(string: url + urlStr) else {
                completionhandler(nil, "Wrong url")
                return
            }
            var headers: HTTPHeaders = ["Content-Type": contentType]
            if isShowActivityIndicator {
                self.startHUD()
            }
            if let appToken = APPDELEGATE.settings?.apiToken, passUserInfoInHeader {
                headers["x-access-token"] = appToken
            }
            var methodNameStr = .post as HTTPMethod
            if methodName.rawValue == "POST" {
                if imageBody.count>0 {
                    AF.upload(multipartFormData: { multipartFormData in
                        for imageData in imageBody {
                            let loopDic = imageData as! NSDictionary
                            let imageData = loopDic[P_DATA] as! Data
                            let NameStr = loopDic[P_NAME] as! String
                            let fileNameStr = loopDic[P_FILENAME] as! String
                            let mimeTypeStr = loopDic[P_MIMETYPE] as! String
                            multipartFormData.append(imageData, withName: NameStr, fileName: fileNameStr, mimeType: mimeTypeStr)
                        }
                        for (key, value) in body {
                            multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as! String)
                        }
                    }, to: url, method: methodNameStr , headers: headers) .responseJSON(completionHandler: { (response:DataResponse) in
                        if self.isUnAuthentication(response.response?.statusCode ?? 404) {
                            return
                        }
                        switch(response.result) {
                        case .success:
                            if response.data != nil
                            {
                                do
                                    {
                                        if let jsonData = try JSONSerialization.jsonObject(with: response.data!, options: []) as? NSDictionary
                                        {
                                            if isShowActivityIndicator {
                                                self.stopHUD()
                                            }
                                            completionhandler(jsonData,"")
                                        }
                                    }
                                catch{
                                    if isShowActivityIndicator {
                                        self.stopHUD()
                                    }
                                    completionhandler(nil,error.localizedDescription)
                                }
                            }
                        case .failure(let error):
                            if isShowActivityIndicator {
                                self.stopHUD()
                            }
                            completionhandler(nil,error.localizedDescription)
                        }

                    })
                }else{
                    print("url :- \(url)")
                    print("parameter :- \(body)")
                    AF.request(url, method: methodNameStr, parameters: body as? Parameters, encoding: parameterEncoding, headers: headers).responseJSON { (response:DataResponse) in
                        if self.isUnAuthentication(response.response?.statusCode ?? 404) {
                            return
                        }
                        switch(response.result)
                        {
                        case .success(_):
                            if response.data != nil
                            {
                                do
                                {
                                    print("Response : \(String(data: response.data!, encoding: .utf8))")
                                    if let jsonData = try JSONSerialization.jsonObject(with: response.data!, options: []) as? NSDictionary
                                    {
                                        if isShowActivityIndicator {
                                            self.stopHUD()
                                        }
                                        completionhandler(jsonData,"")
                                    } else if let jsonData = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [[String : Any]] {
                                        let jsonData1:NSDictionary = ["Response" : jsonData as [[String : Any?]]]
                                        completionhandler(jsonData1,"")
                                        if isShowActivityIndicator {
                                            self.stopHUD()
                                        }
                                    }
                                }
                                catch{
                                    if isShowActivityIndicator {
                                        self.stopHUD()
                                    }
                                    if let returnData = String(data: response.data!, encoding: String.Encoding.utf8) {
                                        let jsonData:NSDictionary = ["Response" : returnData as String]
                                        completionhandler(jsonData,"")
                                    } else {
                                        completionhandler(nil,error.localizedDescription)
                                    }
                                }
                            }
                            break
                        case .failure(let error):
                            if isShowActivityIndicator {
                                self.stopHUD()
                            }
                            if isShowActivityIndicator {
                                self.stopHUD()
                            }
                            completionhandler(nil,error.localizedDescription)

                            break
                        }
                    }
                }
            } else {
                methodNameStr = .get as HTTPMethod
                AF.request(url, method: methodNameStr, parameters: body as? Parameters, encoding: URLEncoding.default, headers: headers).responseJSON { (response:DataResponse) in
                    if self.isUnAuthentication(response.response?.statusCode ?? 404) {
                        return
                    }
                    switch(response.result)
                    {
                    case .success( _):
                        if response.data != nil
                        {

                            do
                            {
                                if let jsonData = try JSONSerialization.jsonObject(with: response.data!, options: []) as? NSDictionary{
                                    
                                    completionhandler(jsonData,"")
                                } else if let jsonData = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [[String : Any]] {
                                    let jsonData1:NSDictionary = ["Response" : jsonData as [[String : Any?]]]
                                    completionhandler(jsonData1,"")
                                    
                                } else if let jsonData = try JSONSerialization.jsonObject(with: response.data!, options: []) as? NSArray {
                                    let jsonData1:NSDictionary = ["Response" : jsonData as? [NSArray] ?? []]
                                    completionhandler(jsonData1,"")
                                    
                                } else {
                                    if let returnData = String(data: response.data!, encoding: String.Encoding.utf8) {
                                        let jsonData:NSDictionary = ["Response" : returnData as String]
                                        completionhandler(jsonData,"")
                                        
                                    }
                                }
                                if isShowActivityIndicator {
                                    self.stopHUD()
                                }
                            }
                            catch{
                                if isShowActivityIndicator {
                                    self.stopHUD()
                                }
                                if let returnData = String(data: response.data!, encoding: String.Encoding.utf8) {
                                    let jsonData:NSDictionary = ["Response" : returnData as String]
                                    completionhandler(jsonData,"")
                                    if isShowActivityIndicator {
                                        self.stopHUD()
                                    }
                                } else {
                                    completionhandler(nil,error.localizedDescription)
                                    if isShowActivityIndicator {
                                        self.stopHUD()
                                    }
                                }
                            }
                        }
                        if isShowActivityIndicator {
                            self.stopHUD()
                        }
                        break

                    case .failure(let error):
                        if isShowActivityIndicator {
                            self.stopHUD()
                        }
                            completionhandler(nil,error.localizedDescription)
                        break
                    }
                }
            }
        }
        else
        {
           // alert(title: ALERT_TITLE, msg: NoInternet)
        }
    }
    
    func stopHUD(){
        DispatchQueue.main.async {
           // APPLICATION.stopActivityIndicator()
        }
    }
    
    func startHUD(){
        DispatchQueue.main.async {
          //  APPLICATION.startActivityIndicator()
        }
    }
    
    func isUnAuthentication(_ statusCode: Int) -> Bool {
        if statusCode == 401 {
            self.stopHUD()
            //APPLICATION.gotoLoginViewController()
        }
        return statusCode == 401
    }
    
}

private func generateBoundaryString() -> String {
    return "Boundary-\(UUID().uuidString)"
}
extension NSMutableData {
    func appendString(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}
extension ApiHandlerClass
{
    static func stringFromDictionary(bodyParam:NSMutableDictionary) -> NSMutableString
    {
        let apiString = NSMutableString()
        for key in bodyParam.allKeys
        {
            if apiString.length != 0
            {
                apiString.append("&")
            }
            if bodyParam[key as!  String] is NSString
            {
                let str = "\(bodyParam.value(forKey: key as! String)!)"
                bodyParam[key as! String] = str.replacingOccurrences(of: "&", with: "%26")
            }
            else if bodyParam[key as! String] is NSNumber
            {
                bodyParam[key as! String] = "\(bodyParam.value(forKey: key as! String) ?? "")"
            }
            apiString.append("\(key)=\(bodyParam[key as! String]!)")
        }
        return apiString
    }
    
    static func setBody(bodyData:NSMutableDictionary?) -> NSMutableDictionary
    {
        var body = NSMutableDictionary()
        if bodyData != nil
        {
            body = bodyData!.mutableCopy() as! NSMutableDictionary
        }
        else{
            body = NSMutableDictionary()
        }
        return body
    }
    
    enum APIMethod:String {
        case GET = "GET"
        case POST = "POST"
        case PATCH = "PATCH"
        case PUT = "PUT"
        case DELETE = "DELETE"
    }
}

////Parse Data
//static func parse(_ json: [String: Any]) -> SampleModel {
//    let ke = json[""] as? String ?? ""
//    if let arr = json["arr"] as? [NSDictionary] {
//        for i in arr {
//            ar.app
//        }
//    }
//}

//func example {
//    let paraDic = NSMutableDictionary.init()
//    paraDic.setValue("", forKey: "sample")
//    paraDic.mutableCopy()
//    
//    ApiHandlerClass.shared().apiCall(methodName: .POST, apiName: "", body: paraDic, imageBody: NSMutableArray(), passUserInfoInHeader: true, isShowActivityIndicator: true, contentType: "application/json", url: "", parameterEncoding: JSONEncoding.default) { (response, result) in
//        if let dicObj = response {
//            if let resultData = dicObj["status"] as? Bool, resultData {
//                if let passData = response?["details"] as? [[String : Any]] {
//                    for sample in sampple {
//                        
//                    }
//                }
//            } else {
//                let message = dicObj["message"] as? String ?? ""
//                alert(title: ALERT_TITLE, msg: message)
//            }
//        }else{
//            ShowErrorMessagePopup(response: response)
//        }
//    }
//}
