//
//  General.swift
//  iOS_Graph_Plug
//
//  Created by macbook pro on 15/02/19.
//  Copyright © 2019 Omni-Bridge. All rights reserved.
//

import UIKit
import SystemConfiguration

// MARK: - General class
class General{
    static let DEFAULT_DATE_FORMATOR = "dd/MM/yyyy"
    static let API_DATE_FORMATOR = "yyyy-MM-dd"
    /// Used to convert date to given date formator type
    ///
    /// - Parameters:
    ///   - date: date
    ///   - formatorStr: required formator
    /// - Returns: formated date
    class func formatedDate(date : Date ,formatorStr : String)-> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatorStr
        return dateFormatter.string(from: date)
    }
    
    /// Used to convert string to date
    ///
    /// - Parameters:
    ///   - strDate: strDate
    ///   - formator: strDate formaor
    /// - Returns: date
    class func stringToDateConvertor(strDate : String , formator : String)-> Date{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formator
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT+0:00")
        return dateFormatter.date(from: strDate)!
    }
    
    /// Used to convert second in time as HH:MM:SS format
    ///
    /// - Parameter seconds: seconds
    /// - Returns: HH:MM:SS format
    class func toHHMMSSConvertor(seconds : Int)-> String{
        var formatedTime = ""
        formatedTime += "\((seconds / 3600) < 10 ? "0\((seconds / 3600))":"\((seconds / 3600))"):"
        formatedTime += "\(((seconds % 3600) / 60) < 10 ? "0\((seconds % 3600) / 60)":"\((seconds % 3600) / 60)"):"
        formatedTime += "\(((seconds % 3600) % 60) < 10 ? "0\((seconds % 3600) % 60)":"\((seconds % 3600) % 60)")"
        return formatedTime
    }
    
    /// Used to check connectivity
    ///
    /// - Returns: flag
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let isConnected = (isReachable && !needsConnection)
        
        return isConnected
    }
}

/// Collection of Error messages
enum Error_Message{
    static let NETWORK_FAILURE_TITLE = "Network failure!"
    static let NETWORK_FAILURE_MESSAGE = "No internet available. Please check your connection."
    
    static let SERVERSIDE_FAILURE_TITLE = "Somwthing went wrong. Please contact to your Admin!"
    static let SERVERSIDE_FAILURE_MESSAGE = "Oops!"
}
