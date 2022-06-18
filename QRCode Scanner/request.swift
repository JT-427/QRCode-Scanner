//
//  request.swift
//  QRCode Scanner
//
//  Created by JT on 2022/6/9.
//

import Foundation
struct SendSK: Encodable {
    let sk: String
    let activity_id: String
}

struct RollcallResponseResult: Decodable{
    let result: String
}

struct RollcallResponseFail: Decodable{
    let message: String?
}
struct RollcallResponseSuccess: Decodable{
    let message: ResponseMessage
}
struct ResponseMessage: Decodable {
    let name: String
    let group: String
    let message: String
}
class Request{
    let domainName: String
    let qrcode: String
    
    init(domainName:String, qrcode: String) {
        self.domainName = domainName
        self.qrcode = qrcode
    }
    typealias completeClosure = ( _ data: Data?, _ error: Error?)->Void
    
    func sendRequest(callback: @escaping completeClosure){
        let url = URL(string: domainName + qrcode)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        let sk = SendSK(sk: "382u+)^$#Cßå©∆fbjds893@#@TRG!", activity_id: activity_id_choosed)
        let data = try? encoder.encode(sk)
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            callback(data, error)
        }.resume()
    }
}
