//
//  getinfo.swift
//  QRCode Scanner
//
//  Created by JT on 2022/6/9.
//

import Foundation



struct Activities: Decodable{
    let activity_id: String
    let activity_name: String
    let start_time: String
}

struct ActivityResponse: Decodable {
    let result: String
    let activities: [Activities]?
    
}

class GetActivities{
    let domainName: String
    init(domainName:String) {
        self.domainName = domainName
    }
    
    typealias completeClosure = ( _ data: Data?, _ error: Error?)->Void
    
    func sendRequest(callback: @escaping completeClosure){
        let url = URL(string: self.domainName+"/api/get_activities_info")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request){ data, response, error in
            callback(data, error)
        }.resume()
    }
}

