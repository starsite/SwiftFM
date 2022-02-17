//
//  SwiftFM.swift
//
//  Created by Brian Hamm on 9/16/18.
//  Refactored for async/await and Codable on 2/14/22.
//
//  Copyright © 2018-2022 Brian Hamm. All rights reserved.
//


import Foundation
import SwiftUI


open class SwiftFM {
    
    
    // MARK: - new session -> .token?
    
    open class func newSession() async -> String? {
        
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
    
    open class func validateSession(token: String) async -> Bool {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/validateSession")
        
        else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
//    open class func deleteSession(token: String) async -> Bool {
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
    
    open class func deleteSession(token: String, completion: @escaping (Bool) -> Void) {
        
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

    
    
    
    
    
    // MARK: - find request -> ([record]?, dataInfo?)
    
    open class func query(layout: String, payload: [String: Any], token: String) async -> (Data?, Data?) {
                
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/_find"),
                let body = try? JSONSerialization.data(withJSONObject: payload)
        
        else { return (nil, nil) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let response  = json["response"] as? [String: Any],
                let messages  = json["messages"] as? [[String: Any]],
                let message   = messages[0]["message"] as? String,
                let code      = messages[0]["code"] as? String
        
        else { return (nil, nil) }
            
        // return
        switch code {
        case "0":
            guard  let data     = response["data"] as? [[String: Any]],
                   let dataInfo = response["dataInfo"] as? [String: Any],
                   let records  = try? JSONSerialization.data(withJSONObject: data),
                   let info     = try? JSONSerialization.data(withJSONObject: dataInfo)
            
            else { return (nil, nil) }
            
            print("fetched \(data.count) records")
            return (records, info)
            
        default:
            print(message)
            return (nil, nil)
        }
    }
    
    
    
    
    
    
    // MARK: - get records -> ([record]?, dataInfo?)
    
    open class func getRecords(layout: String,
                               limit: Int,
                               sortField: String,
                               ascending: Bool = true,
                               portal: String = "[]",
                               token: String) async -> (Data?, Data?) {
        
        
        let order = ascending ? "ascend" : "descend"
        
        let json = """
        [{"fieldName":"\(sortField)","sortOrder":"\(order)"}]
        """
        
        guard let data = json.data(using: .utf8),
              let str = String(data: data, encoding: .utf8),
              let enc = str.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                
        else { return (nil, nil) }

        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records/?_limit=\(limit)&_sort=\(enc)&portal=\(portal)") else {
                    
        return (nil, nil) }
        
        print(url)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let response  = json["response"] as? [String: Any],
                let messages  = json["messages"] as? [[String: Any]],
                let message   = messages[0]["message"] as? String,
                let code      = messages[0]["code"] as? String
                    
        else { return (nil, nil) }
        
        // return
        switch code {
        case "0":
            guard  let data     = response["data"] as? [[String: Any]],
                   let dataInfo = response["dataInfo"] as? [String: Any],
                   let records  = try? JSONSerialization.data(withJSONObject: data),
                   let info     = try? JSONSerialization.data(withJSONObject: dataInfo)
                    
            else { return (nil, nil) }
            
            print("fetched \(data.count) records")
            return (records, info)
            
        default:
            print(message)
            return (nil, nil)
        }
    }

    
    
    
    
    
    // MARK: - get record with id -> ([record]?, dataInfo?)
    
    open class func getRecord(id: Int, layout: String, token: String) async -> (Data?, Data?) {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records/\(id)") else {
                    
        return (nil, nil) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let response  = json["response"] as? [String: Any],
                let messages  = json["messages"] as? [[String: Any]],
                let message   = messages[0]["message"] as? String,
                let code      = messages[0]["code"] as? String
                    
        else { return (nil, nil) }
        
        // return
        switch code {
        case "0":
            guard  let data     = response["data"] as? [[String: Any]],
                   let data0    = data.first,
                   let dataInfo = response["dataInfo"] as? [String: Any],
                   let record   = try? JSONSerialization.data(withJSONObject: data0),
                   let info     = try? JSONSerialization.data(withJSONObject: dataInfo)
                    
            else { return (nil, nil) }
            
            print("fetched recordId: \(id)")
            return (record, info)
            
        default:
            print(message)
            return (nil, nil)
        }
    }
    

    
    
    
    
    // MARK: - create record -> .recordId?
    
    open class func createRecord(layout: String, payload: [String: Any] = ["fieldData":[]], token: String) async -> String? {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records"),
                let body = try? JSONSerialization.data(withJSONObject: payload)
        
        else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMRecord.Result.self, from: data),
                let message   = result.messages.first
                    
        else { return nil }
        
        // return
        switch message.code {
        case "0":
            guard let recordId = result.response.recordId else { return nil }
            
            print("✨ new recordId: \(recordId)")
            return recordId
            
        default:
            print(message)
            return nil
        }
    }
    
    
    
    
    
    
    // MARK: - duplicate record -> .recordId?
    
    open class func duplicateRecord(id: Int, layout: String, token: String) async -> String? {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records/\(id)")
        
        else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMRecord.Result.self, from: data),
                let message   = result.messages.first
                    
        else { return nil }
        
        // return
        switch message.code {
        case "0":
            guard let recordId = result.response.recordId else { return nil }
            
            print("✨ new recordId: \(recordId)")
            return recordId
            
        default:
            print(message)
            return nil
        }
    }

    
    
    
    
    
    // MARK: - edit record -> .modId?
    
    open class func editRecord(id: Int, layout: String, payload: [String: Any], token: String) async -> String? {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records/\(id)"),
                let body = try? JSONSerialization.data(withJSONObject: payload)
        
        else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMRecord.Result.self, from: data),
                let message   = result.messages.first
                    
        else { return nil }
        
        // return
        switch message.code {
        case "0":
            guard let modId = result.response.modId else { return nil }
            
            print("updated modId: \(modId)")
            return modId
            
        default:
            print(message)
            return nil
        }
    }

    
    

    

    // MARK: - set globals -> Bool
    
    open class func setGlobals(payload: [String: Any], token: String) async -> Bool {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/globals"),
                let body = try? JSONSerialization.data(withJSONObject: payload)
                    
        else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMBool.Result.self, from: data),
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
    
    open class func getProductInfo() async -> FMProduct.ProductInfo? {
        
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
            print("product: \(info.name) (\(info.version))")
            
            return info
            
        default:
            print(message)
            return nil
        }
    }


    
    
    
    
    // MARK: - get databases -> .databases?
    
    open class func getDatabases() async -> [FMDatabases.Database]? {
        
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
    
    open class func getLayouts(token: String) async -> [FMLayouts.Layout]? {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts")
                    
        else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
    
    open class func getLayoutMetadata(layout: String, token: String) async -> FMLayoutMetaData.Response? {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)")
                    
        else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
    
    
    
    
    
    
    // MARK: - get scripts -> .scripts?
    
    open class func getScripts(token: String) async -> [FMScripts.Script]? {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/scripts")
                    
        else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMScripts.Result.self, from: data),
                let message   = result.messages.first
                    
        else { return nil }
        
        // return
        switch message.code {
        case "0":
            let scripts = result.response.scripts
            
            print("\(scripts.count) scripts")
            return scripts
            
        default:
            print(message)
            return nil
        }
    }

    
    
    
    
    
    
    // MARK: - execute script -> Bool
    
    open class func executeScript(script: String, parameter: String = "", layout: String, token: String) async -> Bool {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/script/\(script)?script.param=\(parameter)")
                    
        else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMBool.Result.self, from: data),
                let message   = result.messages.first
                    
        else { return false }
        
        // return
        switch message.code {
        case "0":
            
            print("fired script: \(script)")
            return true
            
        default:
            print(message)
            return false
        }
    }

    
    
    
    
    
    // MARK: - set container -> fileName?

    open class func setContainer(recordId: Int,
                                 layout: String,
                                 container: String,
                                 filePath: URL,
                                 inferType: Bool = true,
                                 token: String) async -> String? {
        
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records/\(recordId)/containers/\(container)")
                    
        else { return nil }
        
        
        // request
        let boundary = UUID().uuidString

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        
        // file data
        guard let fileData = try? Data(contentsOf: filePath) else { return nil }
        
        let mimeType = inferType ? fileData.mimeType : "application/octet-stream"
        
        
        // body
        let br = "\r\n"
        let fileName = filePath.lastPathComponent     // ✨ <-- method return

        var httpBody = Data()
        httpBody.append("\(br)--\(boundary)\(br)")
        httpBody.append("Content-Disposition: form-data; name=upload; filename=\(fileName)\(br)")
        httpBody.append("Content-Type: \(mimeType)\(br)\(br)")
        httpBody.append(fileData)
        httpBody.append("\(br)--\(boundary)--\(br)")
        
        request.setValue(String(httpBody.count), forHTTPHeaderField: "Content-Length")
        request.httpBody = httpBody

        
        // session
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMBool.Result.self, from: data),
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









