//
//  MVVMApiClass.swift
//  MVVM+MVCKingClass
//
//  Created by MacBook on 16/07/23.
//

import Foundation
import Alamofire

struct APIConstant {
    static let parseErrorDomain = "ParseError"
    static let parseErrorMessage = "Unable to parse data"
    static let parseErrorCode = Int(UInt8.max)
    static let content_type = "Content-Type"
    static let device_type = "Device-Type"
    static let Authorization = "Authorization"
    static let content_value_urlencoded = "application/x-www-form-urlencoded"
    static let content_value_Json = "application/json"
    static let content_value_Form_Data = "multipart/form-data"
}

let P_URL="URL"
let P_DATA="DATA"
let P_NAME="NAME"
let P_FILENAME="FILENAME"
let P_MIMETYPE="MIMETYPE"
let MIME_TYPE_IMAGE_JPEG="image/jpeg"
let MIME_TYPE_IMAGE_PNG="image/png"
let MIME_TYPE_IMAGE_ALL="image/*"
let MIME_TYPE_VIDEO_ALL="video/mp4"
let MIME_TYPE_FILE = "File/file"


private var sharedApi:ApiHandlerClass? = nil

class ApiHandlerClass: NSObject {
    
    class func shared() -> ApiHandlerClass
    {
        if sharedApi == nil { sharedApi = ApiHandlerClass() }
        return sharedApi!
    }
    
    
    func postApiCall<T:Decodable>(modelClass:T.Type?,
                                    apiName:String?,
                                    body:Parameters,
                                    passUserInfoInHeader : Bool,
                                    isShowActivityIndicator : Bool,
                                    contentType : String,url : String, parameterEncoding:ParameterEncoding,
                                    SuccessBlock:@escaping (T) -> Void,
                                    FailureBlock:@escaping (Error)-> Void)
    {
        if Reachability().connectionStatus().isOnline()
        {
            let url = URL.init(string: url + apiName!)!
            var headers: HTTPHeaders = [APIConstant.content_type: contentType]
            if isShowActivityIndicator {
                self.startHUD()
            }
//            if let appToken = Settings.getInstance().apiToken, passUserInfoInHeader {
//                headers["x-access-token"] = appToken
//            }
            print("url :- \(url)")
            print("parameter :- \(body)")
            AF.request(url, method: .post, parameters: body as? Parameters, encoding: parameterEncoding, headers: headers).response(completionHandler: { (response) in
                if self.isUnAuthentication(response.response?.statusCode ?? 404, data: response.data ?? nil) {
                    return
                }
                switch(response.result) {
                case .success:
                    if isShowActivityIndicator {
                        self.stopHUD()
                    }
                    guard let data = response.data else {
                        FailureBlock(self.handleParseError(Data())) //Show Custom Parsing Error
                        return
                    }
                    //Just for printing response in Json to visualise...
                    do {
                        
                        guard let jsonResult = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary else{ return }
                        //Server Side error handling...
                        print("jsonResult: ", jsonResult)
                        print("URL://==========================//\(url)")
                        print("//==========================//\(jsonResult)")
                        
                    } catch let error{
                        print(error)
                        FailureBlock(error)
                    }
                    
                    
                    //Model Parsing here...
                    do {
                        if isShowActivityIndicator {
                            self.stopHUD()
                        }
                        let objModalClass = try JSONDecoder().decode(modelClass!,from: data)
//                        print(objModalClass)
                        SuccessBlock(objModalClass)
                    } catch let error { //If model class parsing fail
//                        Application.alertPopupController(message: APIErrorMessage.SomethingWentWrong)
                        FailureBlock(error)
                    }
                    
                case .failure(let error):
                    if isShowActivityIndicator { self.stopHUD() }
                    FailureBlock(error)
                }
            })
        } else {
            //Application.alertPopupController(message: APIErrorMessage.NoInternet)
        }
    }
    
    func getApiCall<T:Decodable>(modelClass:T.Type?,
                                    apiName:String?,
                                    body:NSMutableDictionary,
                                    passUserInfoInHeader : Bool,
                                    isShowActivityIndicator : Bool,
                                    contentType : String,url : String, parameterEncoding:ParameterEncoding,
                                    SuccessBlock:@escaping (T) -> Void,
                                    FailureBlock:@escaping (Error)-> Void)
    {
        if Reachability().connectionStatus().isOnline()
        {
            let url = URL.init(string: url + apiName!)!
            var headers: HTTPHeaders = [APIConstant.content_type: contentType]
            if isShowActivityIndicator {
                self.startHUD()
            }
//            if let appToken = Settings.getInstance().apiToken, passUserInfoInHeader {
//                headers["x-access-token"] = appToken
//            }
            print("url :- \(url)")
            print("parameter :- \(body)")
            AF.request(url, method: .get, parameters: body as? Parameters, encoding: URLEncoding.default, headers: headers).response(completionHandler: { (response) in
                if self.isUnAuthentication(response.response?.statusCode ?? 404, data: response.data) {
                    return
                }
                switch(response.result) {
                case .success:
                    
                    if isShowActivityIndicator {
                        self.stopHUD()
                    }

                    guard let data = response.data else { FailureBlock(self.handleParseError(Data()))
                    return }
                    
                    //Just for printing response in Json to visualise...
                    do {
                        guard let jsonResult = try JSONSerialization.jsonObject(with: data, options:
                                                                                    JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary else{
                            return
                        }
                        
                        print("URL://==========================//\(url)")
                        print("//==========================//\(jsonResult)")
                        
                    }catch let error{
                        print(error)
                        //self.showToastMessage(title: msg_NoValidResponseInAPI)
                    }
                    
                    
                    //Model Parsing...
                    do {
                        let objModalClass = try JSONDecoder().decode(modelClass!,from: data)
//                        print(objModalClass)
                        
                        if isShowActivityIndicator {
                            self.stopHUD()
                        }
                        SuccessBlock(objModalClass)
                    } catch let error { //If model class parsing fail
                        
                        print(error)
                     //   Application.alertPopupController(message: APIErrorMessage.SomethingWentWrong)
                        FailureBlock(error)
                    }
                    
                    
                case .failure(let error):
                    if isShowActivityIndicator {
                        self.stopHUD()
                    }
                    FailureBlock(error)
                }
            })
        } else {
           // Application.alertPopupController(message: APIErrorMessage.NoInternet)
        }
    }
    
    func multipartApiCalls<T:Decodable>(modelClass:T.Type?,
                                        apiName:String?,
                                        body:NSMutableDictionary,
                                        imageBody:NSMutableArray,
                                        passUserInfoInHeader : Bool,
                                        isShowActivityIndicator : Bool,
                                        contentType : String,url : String, parameterEncoding:ParameterEncoding,
                                        SuccessBlock:@escaping (T) -> Void,
                                        FailureBlock:@escaping (Error)-> Void) {
        if Reachability().connectionStatus().isOnline()
        {
            let url = URL.init(string: url + apiName!)!
            var headers: HTTPHeaders = [APIConstant.content_type: contentType]
            if isShowActivityIndicator {
                self.startHUD()
            }
//            if let appToken = Settings.getInstance().apiToken, passUserInfoInHeader {
//                headers["x-access-token"] = appToken
//            }
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
            }, to: url, method: .post , headers: headers) .response(completionHandler: { (response) in
                
                if self.isUnAuthentication(response.response?.statusCode ?? 404, data: response.data) { return }
                switch(response.result) {
                case .success:
                    guard let data = response.data else {
                        FailureBlock(self.handleParseError(Data())) //Show Custom Parsing Error
                        return
                    }
                    
                    do {
                        guard let jsonResult = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary else { return }
                        
                        print("URL://==========================//\(url)")
                        print("//==========================//\(jsonResult)")
                        
                    }catch let error{
                        print(error)
                        //self.showToastMessage(title: msg_NoValidResponseInAPI)
                    }
                    
                    
                    //Model Parsing...
                    do {
                        let objModalClass = try JSONDecoder().decode(modelClass!,from: data)
//                        print(objModalClass)
                        if isShowActivityIndicator {
                            self.stopHUD()
                        }
                        SuccessBlock(objModalClass)
                    } catch let error { //If model class parsing fail
                        
                        print(error)
//                        Application.alertPopupController(message: APIErrorMessage.SomethingWentWrong)
                        FailureBlock(error)
                    }
                    
                    
                case .failure(let error):
                    if isShowActivityIndicator {
                        self.stopHUD()
                    }
                    FailureBlock(error)
                }
                
            })
        } else {
            //Application.alertPopupController(message: APIErrorMessage.NoInternet)
        }
    }
    
    //MARK: - Supporting Methods
    fileprivate func handleParseError(_ data: Data) -> Error{
        let error = NSError(domain:APIConstant.parseErrorDomain, code:APIConstant.parseErrorCode, userInfo:[ NSLocalizedDescriptionKey: APIConstant.parseErrorMessage])
        
        print(error.localizedDescription)
      //  Application.alertPopupController(message: error.localizedDescription)
        
        do { //To print response if parsing fail
            let response  = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            print(response)
        }catch{}
        
        return error
    }
    
    func stopHUD(){
        DispatchQueue.main.async {
           // APPLICATION.stopActivityIndicator()
        }
    }
    
    func startHUD(){
        DispatchQueue.main.async {
            //APPLICATION.startActivityIndicator()
        }
    }
    
    func isUnAuthentication(_ statusCode: Int, data: Data?) -> Bool {
        if statusCode == 401 {
            self.stopHUD()
            if let data = data {
                do {
                    guard let jsonResult = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary else {
                        self.showErrorMessage(message: "STATUS_CODE_MSG.MSG_401")
                        return true
                    }
                    
                    //Server Side error handling...
                    let errorMessage = jsonResult["message"] as? String ?? "STATUS_CODE_MSG.MSG_401"
                    self.showErrorMessage(message: errorMessage)
                } catch {
                    self.showErrorMessage(message: "STATUS_CODE_MSG.MSG_401")
                }
            } else {
                self.showErrorMessage(message: "STATUS_CODE_MSG.MSG_401")
            }
            return true
        } else if let data = data {
            do {
                guard let jsonResult = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary else {
                    self.stopHUD()
            //        Application.alertPopupController(message: APIErrorMessage.SomethingWentWrong)
                    return true
                }
                
                //Server Side error handling...
                if let tokenValid = jsonResult["token_valid"] as? Int , tokenValid == 0 {
                    self.stopHUD()
                    self.showErrorMessage(message: "STATUS_CODE_MSG.MSG_401")
                    return true
                } else {
                    return false
                }
                
            } catch {
                self.stopHUD()
            //    Application.alertPopupController(message: APIErrorMessage.SomethingWentWrong)
                return true
            }
            
        }
        return statusCode == 401
    }
    
    func showErrorMessage(message: String) {
    //Alert
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

//Expample


//final class SampleViewModel {
//    var sampleData = Bindable<[Sample]>()
//    var errorMessage = Bindable<Error>()
//
//
//    func getData() {
//        ApiHandlerClass.shared().getApiCall(modelClass: SampleBaseModel.self, apiName: "Endpoint", body: NSMutableDictionary.init(), passUserInfoInHeader: false, isShowActivityIndicator: true, contentType: APIConstant.content_value_Json, url: "BaseUrl", parameterEncoding: JSONEncoding.default) { response in
//            if let status = response.success, (status != 0) {
//                self.screenerData.value =
//            } else {
//                Alert.shared.showAlert(title: appName, message: APIErrorMessage.SomethingWentWrong)
//            }
//        } FailureBlock: { error in
//            self.errorMessage.value = error
//        }
//
//    }
//}

extension exampleController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isKind(of: UITableView.self) {
            if !isFetchingData {
                let scrollViewHeight = scrollView.frame.size.height
                let scrollContentSizeHeight = scrollView.contentSize.height
                let scrollOffset = scrollView.contentOffset.y
                
                if scrollOffset + scrollViewHeight >= scrollContentSizeHeight - 50 {
                    if !noMoreRecordsAvailable {
                        isFetchingData = true
                        skip += 10
                        self.getNewsData()
                    }
                }
            }
        }
    }
}
