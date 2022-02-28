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
    
    /// Fetches a new Data API session token
    ///
    /// - Returns: An optional `token`, which is also saved to `UserDefaults` under a `fm-token` key
    /// - Note: Prior to calling this, you need to have some environment variables set.
    ///
    /// **UIKit**: Set your environment in `AppDelegate`, inside `applicationWillEnterForeground(_:)`
    ///
    /// **SwiftUI**: Set your environment in `MyApp:App`, inside an `init()`. Alternatively, these could also be saved to an `@EnvironmentObject`.
    ///
    /// The `auth` value will be passed later, as part of the `Authorization` header.
    ///
    /// ⚠️ For TESTING, you can set these with string literals. For PRODUCTION, you should be fetching/setting these values from elsewhere. **Do not** deploy apps with credentials visible in code.

    /// ```swift
    /// func applicationWillEnterForeground(_ application: UIApplication) {
    ///
    ///     let host = "my.host.com"  //
    ///     let db   = "my_database"  //
    ///                               //  fetch these from elsewhere, or prompt at launch
    ///     let user = "username"     //
    ///     let pass = "password"     //
    ///
    ///     UserDefaults.standard.set(host, forKey: "fm-host")
    ///     UserDefaults.standard.set(db, forKey: "fm-db")
    ///
    ///     let str = "\(user):\(pass)"
    ///
    ///     if let auth = str.data(using: .utf8)?.base64EncodedString() {
    ///         UserDefaults.standard.set(auth, forKey: "fm-auth")
    ///     }
    /// }
    /// ```
    ///
    /// ```swift
    /// struct MyApp: App {
    ///
    ///     init() {
    ///         let host = "my.host.com"  //
    ///         let db   = "my_database"  //
    ///                                   //  fetch these from elsewhere, or prompt at launch
    ///         let user = "username"     //
    ///         let pass = "password"     //
    ///
    ///         UserDefaults.standard.set(host, forKey: "fm-host")
    ///         UserDefaults.standard.set(db, forKey: "fm-db")
    ///
    ///         let str = "\(user):\(pass)"
    ///
    ///         if let auth = str.data(using: .utf8)?.base64EncodedString() {
    ///             UserDefaults.standard.set(auth, forKey: "fm-auth")
    ///         }
    ///     }
    ///
    ///     var body: some Scene {
    ///         // ...
    ///     }
    /// }
    /// ```

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
        
    /// Verifies an existing Data API session `token`
    ///
    /// - Parameters:
    ///   - token: Data API session token
    ///
    /// - Returns: A `Bool` indicating a in/valid token
    ///
    /// - Note: This can be called anytime but is most useful when wrapping other SwiftFM calls, to ensure you're passing a valid token.
    
    /// ```swift
    /// let token = UserDefaults.standard.string(forKey: "fm-token") ?? ""
    /// let isValid = await SwiftFM.validateSession(token: token)
    ///
    /// switch isValid {
    /// case true:
    ///     fetchArtists(token: token)
    /// case false:
    ///     if let newToken = await SwiftFM.newSession() {
    ///         fetchArtists(token: newToken)
    ///     }
    /// }
    /// ```
    
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
    

    

    
    
    // MARK: - delete session -> @escaping Bool
            
    /// Deletes a Data API session token
    ///
    /// - Parameters:
    ///   - token: Data API session token
    ///
    /// - Returns: A `Bool` indicating a un/successful request
    /// - Note: UIKit: Call this in your AppDelegate, inside `applicationDidEnterBackground`.
    ///
    /// SwiftUI: Call this in `MyApp:App`, inside a `.scenePhase` switch.
    ///
    /// This method uses an `@escaping` closure rather than `async`, in order to work with SwiftUI `.scenePhase` transitions.

    /// ```swift
    /// func applicationDidEnterBackground(_ application: UIApplication) {
    ///
    ///     if let token = UserDefaults.standard.string(forKey: "fm-token") {
    ///         SwiftFM.deleteSession(token: token) { _ in }
    ///     }
    /// }
    /// ```
    /// ```swift
    /// var body: some Scene {
    ///     WindowGroup {
    ///         ContentView()
    ///     }
    ///     .onChange(of: scenePhase) { phase in
    ///         switch phase {
    ///         case .background:
    ///             DispatchQueue.global(qos: .background).async {  // extra time
    ///                 if let token = UserDefaults.standard.string(forKey: "fm-token") {
    ///                     SwiftFM.deleteSession(token: token) { _ in }
    ///                 }
    ///             }
    ///         default: break
    ///         }
    ///     }
    /// }
    /// ```
    
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

    
    
    
    
    
    // MARK: - query -> ([record], .dataInfo)
    
    /// Performs a find request with a `query` payload
    ///
    /// - Parameters:
    ///   - layout: Layout to query
    ///   - payload: JSON object containing a `query` key
    ///   - token: Data API session token
    ///
    /// - Returns: A record array (`Data`) and metadata (`DataInfo`) about the request
    /// - Note: Use `JSONDecoder` to process the record data (`Data, _`). Create a Codable model struct that includes your entity's `fieldData`. Or use `JSONSerialization` to decode the objects manually.
    ///
    /// `DataInfo` properties can be accessed immediately, as in `print(info.foundCount)`.

    /// ```swift
    /// let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""
    /// let layout = "Artists"
    ///
    /// // find artists named Brian or Geoff
    /// let payload = ["query": [
    ///     ["firstName": "Brian"],
    ///     ["firstName": "Geoff"]
    /// ]]
    ///
    /// // find artists named Brian in Dallas
    /// let payload = ["query": [
    ///     ["firstName": "Brian", "city": "Dallas"]
    /// ]]
    ///
    /// guard let (data, _) = try? await SwiftFM.query(layout: layout, payload: payload, token: token),
    ///       let records   = try? JSONDecoder().decode([Artist.Record].self, from: data) else { return }
    ///
    /// self.artists = records  // set @State data source
    /// ```
    
    open class func query(layout: String, payload: [String: Any], token: String) async throws -> (Data, FMResult.DataInfo) {
                
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/_find"),
                let body = try? JSONSerialization.data(withJSONObject: payload)
        
        else { throw FMError.jsonSerialization }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let result    = try? JSONDecoder().decode(FMResult.Result.self, from: data),  // .dataInfo
                let response  = json["response"] as? [String: Any],
                let messages  = json["messages"] as? [[String: Any]],
                let message   = messages[0]["message"] as? String,
                let code      = messages[0]["code"] as? String
        
        else { throw FMError.sessionResponse }
            
        // return
        switch code {
        case "0":
            guard  let data     = response["data"] as? [[String: Any]],
                   let records  = try? JSONSerialization.data(withJSONObject: data),
                   let dataInfo = result.response.dataInfo

            else { throw FMError.jsonSerialization }
            
            print("fetched \(data.count) records")
            return (records, dataInfo)
            
        default:
            print(message)
            throw FMError.nonZeroCode
        }
    }
    
    
    
    
    
    
    // MARK: - get records -> ([record], .dataInfo)
    
    /// Fetches a range of records with a sort order
    ///
    /// - Parameters:
    ///   - layout: Layout to query
    ///   - limit: Constrains the number of records fetched
    ///   - sortField: Field name to sort on
    ///   - ascending: Sets an `ascend` or `descend` value on the results prior to returning
    ///   - portal: Optional portal name (or object name) on `layout`
    ///   - token: Data API session token
    ///
    /// - Returns: A record array (`Data`) and metadata (`DataInfo`) about the request
    /// - Note: Use `JSONDecoder` to process the record data (`Data, _`). Create a Codable model struct that includes your entity's `fieldData`. Or use `JSONSerialization` to decode the objects manually.
    ///
    /// `DataInfo` properties can be accessed immediately, as in `print(info.foundCount)`.
    
    open class func getRecords(layout: String,
                               limit: Int,
                               sortField: String,
                               ascending: Bool,
                               portal: String?,
                               token: String) async throws -> (Data, FMResult.DataInfo) {
        
        // params
        let order = ascending ? "ascend" : "descend"
        
        let sortJson = """
        [{"fieldName":"\(sortField)","sortOrder":"\(order)"}]
        """
        
        var portalJson = "[]"  // nil portal
        
        if let portal = portal {  // else
            portalJson = """
            ["\(portal)"]
            """
        }
                
        
        // encoding
        guard   let sortEnc   = sortJson.urlEncoded,
                let portalEnc = portalJson.urlEncoded,
                let host      = UserDefaults.standard.string(forKey: "fm-host"),
                let db        = UserDefaults.standard.string(forKey: "fm-db"),
                let url       = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records/?_limit=\(limit)&_sort=\(sortEnc)&portal=\(portalEnc)")
        
        else { throw FMError.urlEncoding }
        
        
        // request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let result    = try? JSONDecoder().decode(FMResult.Result.self, from: data),  // .dataInfo
                let response  = json["response"] as? [String: Any],
                let messages  = json["messages"] as? [[String: Any]],
                let message   = messages[0]["message"] as? String,
                let code      = messages[0]["code"] as? String
                    
        else { throw FMError.sessionResponse }
        
        
        // return
        switch code {
        case "0":
            guard  let data     = response["data"] as? [[String: Any]],
                   let records  = try? JSONSerialization.data(withJSONObject: data),
                   let dataInfo = result.response.dataInfo

            else { throw FMError.jsonSerialization }
            
            print("fetched \(data.count) records")
            return (records, dataInfo)
            
        default:
            print(message)
            throw FMError.nonZeroCode
        }
    }

    
    
    
    
    
    // MARK: - get record id -> (record, .dataInfo)

    /// Fetches a single record with a `recordId`
    ///
    /// - Parameters:
    ///   - id: `recordId` of the record to fetch
    ///   - layout: Layout/context for the request
    ///   - token: Data API session token
    ///
    /// - Returns: A record (`Data`) and metadata (`DataInfo`) for the request
    ///
    /// - Note: Use `JSONDecoder` to process the record data (`Data, _`). Create a Codable model struct that includes your entity's `fieldData`. Or use `JSONSerialization` to decode the objects manually.
    ///
    /// `DataInfo` properties can be accessed immediately, as in `print(info.foundCount)`.
    
    open class func getRecord(id: Int, layout: String, token: String) async throws -> (Data, FMResult.DataInfo) {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records/\(id)")
        
        else { throw FMError.urlEncoding }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let result    = try? JSONDecoder().decode(FMResult.Result.self, from: data),  // .dataInfo
                let response  = json["response"] as? [String: Any],
                let messages  = json["messages"] as? [[String: Any]],
                let message   = messages[0]["message"] as? String,
                let code      = messages[0]["code"] as? String
                    
        else { throw FMError.sessionResponse }
        
        // return
        switch code {
        case "0":
            guard  let data     = response["data"] as? [[String: Any]],
                   let data0    = data.first,
                   let record   = try? JSONSerialization.data(withJSONObject: data0),
                   let dataInfo = result.response.dataInfo

            else { throw FMError.jsonSerialization }
            
            print("fetched recordId: \(id)")
            return (record, dataInfo)
            
        default:
            print(message)
            throw FMError.nonZeroCode
        }
    }
    

    
    
    
    
    // MARK: - create record -> .recordId?
    
    /// Creates a new record with an optional `fieldData` payload
    ///
    /// - Parameters:
    ///   - layout: Layout/context for the request
    ///   - payload: Optional JSON object with a `fieldData` key containing the fields you want to set
    ///   - token: Data API session token
    ///
    /// - Returns: The `recordId` for the created record
    /// - Note: Setting a `nil` payload will create an empty record.
    
    /// ```swift
    /// let token = UserDefaults.standard.string(forKey: "fm-token") ?? ""
    /// let layout = "Artists"
    ///
    /// let payload = ["fieldData": [  // required key
    ///     "firstName": "Brian",
    ///     "lastName": "Hamm",
    ///     "email": "hello@starsite.co"
    /// ]]
    ///
    /// if let recordId = await SwiftFM.createRecord(layout: layout, payload: payload, token: token) {
    ///     print("created record: \(recordId)")
    /// }
    /// ```
    
    open class func createRecord(layout: String, payload: [String: Any]?, token: String) async -> String? {
        
        var fieldData: [String: Any] = ["fieldData": [:]]  // nil payload
        
        if let payload = payload {  // else
            fieldData = payload
        }
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records"),
                let body = try? JSONSerialization.data(withJSONObject: fieldData)
        
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
    
    /// Duplicates a record for a specified `recordId`
    ///
    /// - Parameters:
    ///   - id: `recordId` for the record to duplicate
    ///   - layout: Layout/context for the request
    ///   - token: Data API session token
    ///
    /// - Returns: The `recordId` for the created record
    /// - Note: To continue working with the new record, pass the returned `recordId` to a `getRecord(id:)` call

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
    
    /// Modifies a record with an optional `fieldData` payload
    ///
    /// - Parameters:
    ///   - id: `recordId` for the record to modify
    ///   - layout: Layout/context for the request
    ///   - payload: Optional JSON object with a `fieldData` key containing the fields to modify
    ///   - token: Data API session token
    ///
    /// - Returns: An updated `modId` value for the modified record
    /// - Note: If you choose to include a `modId` value in the payload, the record will only be modified if it matches the `modId` value in FileMaker Server. This ensures you're working with the current version of the record. If you do not pass a `modId`, the record will be modfied without this check.

    /// ```swift
    /// let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""
    /// let id     = 12345
    /// let layout = "Artists"
    ///
    /// let payload = ["fieldData": [  // required key
    ///     "email": "my_new@email.com",
    /// ]]
    ///
    /// if let modId = await SwiftFM.editRecord(id: id, layout: layout, payload: payload, token: token) {
    ///     print("updated modId: \(modId)")
    /// }
    /// ```
    
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

    
    
    
    
    
    // MARK: - delete record id -> Bool
    
    /// Deletes a record
    ///
    /// - Parameters:
    ///   - id: `recordId` for the record to delete
    ///   - layout: Layout/context for the request
    ///   - token: Data API session token
    ///
    /// - Returns: A `Bool` indicating a un/successful deletion
    /// - Note: This is Swift, not FileMaker. Nothing will stop this from firing—immediately. Put some kind of confirmation view in your app.

    open class func deleteRecord(id: Int, layout: String, token: String) async -> Bool {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records/\(id)")
        
        else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard   let (data, _) = try? await URLSession.shared.data(for: request),
                let result    = try? JSONDecoder().decode(FMBool.Result.self, from: data),
                let message   = result.messages.first
                    
        else { return false }
        
        // return
        switch message.code {
        case "0":
            print("deleted recordId: \(id)")
            return true
            
        default:
            print(message)
            return false
        }
    }

    

    

    
    // MARK: - set globals -> Bool
    
    /// Sets a global field(s) with a `globalFields` payload
    ///
    /// - Parameters:
    ///   - payload: JSON object with a `globalFields` key containing the fields to be set
    ///   - token: Data API session token
    ///
    /// - Returns: A `Bool` indicating a un/successful request
    /// - Note: Unlike `fieldData` payloads, global fields must be set using fully qualified field names (`table name::field name`).

    /// ```swift
    /// let token = UserDefaults.standard.string(forKey: "fm-token") ?? ""
    ///
    /// let payload = ["globalFields": [  // required key
    ///     "baseTable::gField": "newValue",
    ///     "baseTable::gField2": "newValue"
    /// ]]
    ///
    /// let result = await SwiftFM.setGlobals(payload: payload, token: token)
    ///
    /// if result == true {
    ///     print("globals set")
    /// }
    /// ```
    
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
    
    /// Gets product information for a FileMaker Server
    ///
    /// - Returns: `ProductInfo` containing properties for `.name .buildDate, .version, .dateFormat, .timeFormat`, and `.timeStampFormat`
    /// - Note: This method takes no parameters and doesn't require a session token.
    
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
    
    /// Gets a list of databases available for a FileMaker Server
    ///
    /// - Returns: A `databases` array containing a `.name` property
    /// - Note: This method takes no parameters and doesn't require a session token.
    
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
    
    /// Gets layout information for a FileMaker database
    ///
    /// - Parameters:
    ///   - token: Data API session token
    ///
    /// - Returns: A `layouts` array containing properties for `.name` and `.isFolder`
    /// - Note: Many SwiftFM return types conform to `Comparable`. Use `.sorted()` to order any returned layouts or folders.

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
    
    /// Gets metadata for a specified `layout`
    ///
    /// - Parameters:
    ///   - layout: Layout for the request
    ///   - token: Data API session token
    ///
    /// - Returns: A `response` containing arrays for `.fieldMetaData`, `.portalMetaData` and `.valueLists`
    /// - Note: Many SwiftFM return types conform to `Comparable`. Use `.sorted()` to order any returned fields or value lists.
    
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
    
    /// Gets a list of scripts available for a FileMaker database
    ///
    /// - Parameters:
    ///   - token: Data API session token
    ///
    /// - Returns: A `scripts` array containing properties for `.name` and `.isFolder`
    
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
    
    /// Executes a script with an optional `parameter`
    ///
    /// - Parameters:
    ///   - script: Script name to execute
    ///   - parameter: Optional script parameter value to pass
    ///   - layout: Layout/context to fire the script
    ///   - token: Data API session token
    ///
    /// - Returns: A `Bool` indicating a un/successful request
    /// - Note: Script names and parameters are URL encoded, so spaces and such are ok.
    
    open class func executeScript(script: String, parameter: String?, layout: String, token: String) async -> Bool {
        
        
        var param = ""  // nil parameter
        
        if let parameter = parameter {  // else
            param = parameter
        }
        
        
        // encoding
        guard   let scriptEnc = script.urlEncoded,
                let paramEnc  = param.urlEncoded,
                let host      = UserDefaults.standard.string(forKey: "fm-host"),
                let db        = UserDefaults.standard.string(forKey: "fm-db"),
                let url       = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/script/\(scriptEnc)?script.param=\(paramEnc)")
                    
        else { return false }
        
        
        // request
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
    
    /// Sets a record container field with `Data`
    ///
    /// - Parameters:
    ///   - recordId: Id for the record to update
    ///   - layout: Layout including the container to be set
    ///   - container: Field object name for the container to set
    ///   - filePath: URL for the file you want to upload
    ///   - inferType: `Bool` indicating whether or not to sniff the file mime-type
    ///   - token: Data API session token
    ///
    /// - Returns: The `fileName` of the file used to set the container
    /// - Note: An `inferType` of false will set a default "application/octet-stream" value for the mime-type

    /// ```swift
    /// let token     = UserDefaults.standard.string(forKey: "fm-token") ?? ""
    /// let id        = 12345
    /// let layout    = "Artists"
    /// let container = "headshot"
    ///
    /// guard let path = URL(string: "http://starsite.co/brian_memoji.png"),
    ///       let fileName = await SwiftFM.setContainer(recordId: id,
    ///                                                 layout: layout,
    ///                                                 container: container,
    ///                                                 filePath: path,
    ///                                                 inferType: true,
    ///                                                 token: token)
    /// else { return }
    /// print("container set: \(fileName)")
    /// ```
    
    open class func setContainer(recordId: Int,
                                 layout: String,
                                 container: String,
                                 filePath: URL,
                                 inferType: Bool,
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
    
    
    
    
    
    
    // MARK: - throwing errors
    
    enum FMError: Error {
        case jsonSerialization
        case urlEncoding
        case sessionResponse
        case nonZeroCode
    }

    

    
}  // .SwiftFM 😘



