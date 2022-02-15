//  SwiftFM.swift
//
//  Created by Brian Hamm on 9/16/18.
//  Refactored for async/await and Codable on 2/14/22.
//
//  Copyright © 2018-2022 Brian Hamm. All rights reserved.


import Foundation
import SwiftUI

class SwiftFM {
    
    
    
    // MARK: - new session -> .token?
    
    public class func newSession() async -> String? {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let auth = UserDefaults.standard.string(forKey: "fm-auth"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/sessions")
                    
        else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMSession.Result.self, from: data),
                let message   = result.messages.first
                    
        else { return nil }
        
        // return
        switch message.code {
        case "0":
            guard let token = result.response.token else { return nil }
            
            UserDefaults.standard.set(token, forKey: "fm-token")
            print("✨ new token » \(token)")
            
            return token
            
        default:
            print(message)
            return nil
        }
    }

    
    
    
    
    
    // MARK: - validate session -> Bool
    
    public class func validateSession(token: String) async -> Bool {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/validateSession")
        
        else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMSession.Result.self, from: data),
                let message   = result.messages.first
                
        else { return false }
        
        // return
        switch message.code {
        case "0":
            print("✅ valid token » \(token)")
            return true

        default:
            print(message)
            return false
        }
    }
    
    
    
    
    
        
//    // ❌ we can't use this for .scenePhase.background in SwiftUI... use the @escaping method below
//
//    public class func deleteSession(token: String) async -> Bool {
//
//        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
//                let db   = UserDefaults.standard.string(forKey: "fm-db"),
//                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/sessions/\(token)")
//
//        else { return false }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "DELETE"
//
//        guard   let (data, _) = try? await URLSession.shared.data(for: request),
//                let result    = try? JSONDecoder().decode(FMSession.Result.self, from: data),
//                let message   = result.messages.first
//
//        else { return false }
//
//        // return
//        switch message.code {
//        case "0":
//            UserDefaults.standard.set(nil, forKey: "fm-token")
    
//            print("🔥 deleted token » \(token)")
//            return true
//
//        default:
//            print(message)
//            return false
//        }
//    }
    
    
    

    
    
    // MARK: - delete session -> @escaping Bool
    
    // ✅ we need an @escaping method for .scenePhase.background in SwiftUI
    
    public class func deleteSession(token: String, completion: @escaping (Bool) -> Void) {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/sessions/\(token)")
                    
        else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { data, resp, error in

            guard   let data    = data, error == nil,
                    let result  = try? JSONDecoder().decode(FMSession.Result.self, from: data),
                    let message = result.messages.first

            else { return }

            // return
            switch message.code {
            case "0":
                UserDefaults.standard.set(nil, forKey: "fm-token")
                
                print("🔥 deleted token » \(token)")
                completion(true)

            default:
                print(message)
                completion(false)
            }

        }.resume()
    }

    
    

    
    
    // MARK: - query -> .data?
    
    public class func query(layout: String, payload: [String: Any], token: String) async -> [FMQuery.Record]? {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/_find"),
                let body = try? JSONSerialization.data(withJSONObject: payload)
                    
        else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMQuery.Result.self, from: data),
                let message   = result.messages.first
                    
        else { return nil }
        
        // return
        switch message.code {
        case "0":
            guard let records = result.response.data else { return [] }
            
            print("fetched \(records.count) records")
            return records
            
        default:
            print(message)
            return []
        }
    }
    
    
    
    
    
    
    // MARK: - get record id -> .data?.first

    public class func getRecord(id: Int, layout: String, token: String) async -> FMQuery.Record? {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records/\(id)")
        
        else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMQuery.Result.self, from: data),
                let message   = result.messages.first
                    
        else { return nil }
        
        // return
        switch message.code {
        case "0":
            guard let record = result.response.data?.first else { return nil }
            
            print("fetched recordId: \(record.recordId)")
            return record
            
        default:
            print(message)
            return nil
        }
    }

    
    
    

    
    // MARK: - create record -> .recordId?
    
    public class func createRecord(layout: String, payload: [String: Any], token: String) async -> String? {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records"),
                let body = try? JSONSerialization.data(withJSONObject: payload)
        
        else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMRecord.Result.self, from: data),
                let message   = result.messages.first
                    
        else { return nil }
        
        // return
        switch message.code {
        case "0":
            guard let recordId = result.response.recordId else { return nil }
            
            print("new recordId: \(recordId)")
            return recordId
            
        default:
            print(message)
            return nil
        }
    }
    
    
    
    
    
    
    // MARK: - duplicate record -> .recordId?
    
    public class func duplicateRecord(id: Int, layout: String, token: String) async -> String? {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records/\(id)")
        
        else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMRecord.Result.self, from: data),
                let message   = result.messages.first
                    
        else { return nil }
        
        // return
        switch message.code {
        case "0":
            guard let recordId = result.response.recordId else { return nil }
            
            print("new recordId: \(recordId)")
            return recordId
            
        default:
            print(message)
            return nil
        }
    }

    
    
    
    
    
    // MARK: - edit record -> .modId?
    
    public class func editRecord(id: Int, layout: String, payload: [String: Any], modId: Int?, token: String) async -> String? {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records/\(id)"),
                let body = try? JSONSerialization.data(withJSONObject: payload)
        
        else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMRecord.Result.self, from: data),
                let message   = result.messages.first
                    
        else { return nil }
        
        // return
        switch message.code {
        case "0":
            guard let modId = result.response.modId else { return nil }
            
            print("new modId: \(modId)")
            return modId
            
        default:
            print(message)
            return nil
        }
    }

    
    

    

    // MARK: - set globals -> Bool
    
    public class func setGlobals(payload: [String: Any], token: String) async -> Bool {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/globals"),
                let body = try? JSONSerialization.data(withJSONObject: payload)
                    
        else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMGlobals.Result.self, from: data),
                let message   = result.messages.first
                    
        else { return false }
        
        // return
        switch message.code {
        case "0":
            print("globals set")
            return true
            
        default:
            print(message)
            return false
        }
    }
    
    
    
    
    
    // MARK: - get product info -> .productInfo?
    
    public class func getProductInfo() async -> FMProduct.ProductInfo? {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/productInfo")
                    
        else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMProduct.Result.self, from: data),
                let message   = result.messages.first
                    
        else { return nil }
        
        // return
        switch message.code {
        case "0":
            let info = result.response.productInfo
            
            print("\nProduct Info:\n")
            print("Name: \(info.name)")
            print("Build Date: \(info.buildDate)")
            print("Version: \(info.version)")
            print("Date Format: \(info.dateFormat)")
            print("Time Format: \(info.timeFormat)")
            print("Timestamp Format: \(info.timeStampFormat)")
            
            return info
            
        default:
            print(message)
            return nil
        }
    }


    
    
    
    
    // MARK: - get databases -> .databases?
    
    public class func getDatabases() async -> [FMDatabases.Database]? {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases")
                    
        else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMDatabases.Result.self, from: data),
                let message   = result.messages.first
                    
        else { return nil }
        
        // return
        switch message.code {
        case "0":
            let databases = result.response.databases
            
            print("\(databases.count) databases")
            return databases
                        
        default:
            print(message)
            return nil
        }
    }

    
    
    
    
    
    // MARK: - get layouts -> .layouts?
    
    public class func getLayouts(token: String) async -> [FMLayouts.Layout]? {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts")
                    
        else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMLayouts.Result.self, from: data),
                let message   = result.messages.first
                    
        else { return nil }
        
        // return
        switch message.code {
        case "0":
            let layouts = result.response.layouts
            
            print("\(layouts.count) layouts")
            return layouts
            
        default:
            print(message)
            return nil
        }
    }

    
    
    
    
    
    // MARK: - get layout metadata -> .fieldMetaData?
    
    public class func getLayoutMetadata(layout: String, token: String) async -> FMLayoutMetaData.Response? {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)")
                    
        else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMLayoutMetaData.Result.self, from: data),
                let message   = result.messages.first
                    
        else { return nil }
                
        // return
        switch message.code {
        case "0":
            if let fields = result.response.fieldMetaData {
                print("\(fields.count) fields")
            }
            
            if let valueLists = result.response.valueLists {
                print("\(valueLists.count) value lists")
            }
            
            return result.response
            
        default:
            print(message)
            return nil
        }
    }

    
    
    
    
    
    // MARK: - set container -> fileName?

    public class func setContainer(id: Int, layout: String, containerField: String, filePath: URL, modId: Int?, token: String) async -> String? {
        
        // url
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db = UserDefaults.standard.string(forKey: "fm-db"),
                let url = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records/\(id)/containers/\(containerField)")
                    
        else { return nil }
        
        
        // request
        let boundary = UUID().uuidString

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        
        // file data
        guard let fileData = try? Data(contentsOf: filePath) else { return nil }
        
        let mimeType = fileData.mimeType              // <-- .mimeType is part of DataExtension.swift
//      let mimeType = "application/octet-stream"     // you can use "application/octet-stream" instead, if you're having trouble sniffing the mime type
        
        
        // body
        let br = "\r\n"
        let fileName = filePath.lastPathComponent     // ✨ <-- method return

        var httpBody = Data()
        httpBody.append("\(br)--\(boundary)\(br)")
        httpBody.append("Content-Disposition: form-data; name=upload; filename=\(fileName)\(br)")
        httpBody.append("Content-Type: \(mimeType)\(br)\(br)")
        httpBody.append(fileData)
        httpBody.append("\(br)--\(boundary)--\(br)")
        
        request.addValue(String(httpBody.count), forHTTPHeaderField: "Content-Length")
        request.httpBody = httpBody

        
        // urlsession
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMContainer.Result.self, from: data),
                let message   = result.messages.first
                    
        else { return nil }
        
        
        // return
        switch message.code {
        case "0":
            print("container set: \(fileName)")
            return fileName
            
        default:
            print(message)
            return nil
        }
    }
    

    
    
}  // .SwiftFM 😘









