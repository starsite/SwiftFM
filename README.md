![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/starsite/SwiftFM) ![GitHub](https://img.shields.io/github/license/starsite/SwiftFM) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fstarsite%2FSwiftFM%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/starsite/SwiftFM) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fstarsite%2FSwiftFM%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/starsite/SwiftFM)

# SwiftFM

SwiftFM is a Swift framework for the FileMaker Data API. It uses modern Swift features like `async/await`, `Codable` type-safe returns, and has extensive support for `DocC`.

This `README.md` is aimed at Swift devs who want to use the Data API in their UIKit and SwiftUI projects. Each function shown below is paired with a code example.

SwiftFM is **in no way** related to the FIleMaker iOS App SDK.

---

### 👉 v2.2.0

`query()`, `getRecord()`, and `getRecords()` previously returned `(Data?, Data?)`. Returning a tuple of optionals meant an extra step before unwrapping the result. Not ideal. Starting with 2.2.0, record fetching methods `throw` and will return `(Data, DataInfo)`. This means:

* You no longer need the extra `let (data, info)` call prior to unwrapping either object.
* You can now 'dot' directly into `info`, like this: `print("fetched \(info.returnedCount) records")`.

This behavior more closely mimics a `URLSession` call, which should make it nicer to use.

---

### 🗳 How To Use

* Xcode -> File -> Add Packages
* `https://github.com/starsite/SwiftFM.git`
* **UIKit**: Set your enivronment in `applicationWillEnterForeground(_:)`
* **SwiftUI**: Set your enivronment in `MyApp.init()`
* Add an `import SwiftFM` statement
* Call `SwiftFM.newSession()` and get a token ✨
* Woot!

---

### 🖐 How To Help

This was **a lot** of work. If you'd like to support the SwiftFM project, you can:

* Contribute socially, by giving SwiftFM a ⭐️ on GitHub or telling other people about it
* Contribute [financially](https://paypal.me/starsite) (paypal.me/starsite)
* Hire me to build an iOS app for you or one of your FileMaker clients. 🥰

---

### ✅ Async/await

SwiftFM was rewritten this year to use `async/await`. This requires Swift 5.5 and iOS 15. If you need to compile for iOS 13 or 14, skip SPM and download the repo instead, and convert the `URLSession` calls using `withCheckedContinuation`. For more information on *that*, visit: [Swift by Sundell](https://wwdcbysundell.com/2021/wrapping-completion-handlers-into-async-apis/), [Hacking With Swift](https://www.hackingwithswift.com/quick-start/concurrency/how-to-use-continuations-to-convert-completion-handlers-into-async-functions), or watch Apple's WWDC 2021 [session](https://developer.apple.com/videos/play/wwdc2021/10132/) on the topic.

---

### 📔 Table of Contents

* [`environment variables`](#environment-variables)
* [`newSession()`](#-new-session-function---token)
* [`validateSession(token:)`](#validate-session-function---bool)
* [`deleteSession(token:)`](#delete-session-function---escaping-bool)
* [`createRecord(layout:payload:token:)`](#-create-record-function---recordid)
* [`duplicateRecord(id:layout:token:)`](#duplicate-record-function---recordid)
* [`editRecord(id:layout:payload:token:)`](#edit-record-function---modid)
* [`deleteRecord(id:layout:token:)`](#-delete-record-function---bool)
* [`query(layout:payload:token:)`](#-query-function---record-datainfo)
* [`getRecords(layout:limit:sortField:ascending:portal:token:)`](#get-records-function---record-datainfo)
* [`getRecord(id:layout:token:)`](#get-record-function---record-datainfo)
* [`setGlobals(payload:token:)`](#set-globals-function---bool)
* [`getProductInfo()`](#get-product-info-function---productinfo)
* [`getDatabases()`](#get-databases-function---databases)
* [`getLayouts(token:)`](#get-layouts-function---layouts)
* [`getLayoutMetaData(layout:token:)`](#get-layout-metadata-function---response)
* [`getScripts(token:)`](#get-scripts-function---scripts)
* [`executeScript(script:parameter:layout:token:)`](#execute-script-function---bool)
* [`setContainer(recordId:layout:container:filePath:inferType:token:)`](#set-container-function---filename)

---

### Environment Variables

For TESTING, you can set these with string literals. For PRODUCTION, you should be fetching these values from elsewhere. DO NOT deploy apps with credentials visible in code. 😵

#### Example: Swift (UIKit)

Set your environment in `AppDelegate` inside `applicationWillEnterForeground(_:)`. 

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    // ...
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        let host = "my.host.com"  //
        let db   = "my_database"  //
                                  //  these should be fetched elsewhere, or prompted at launch
        let user = "username"     //
        let pass = "password"     //

        UserDefaults.standard.set(host, forKey: "fm-host")
        UserDefaults.standard.set(db, forKey: "fm-db")
        
        let str = "\(user):\(pass)"
        
        if let auth = str.data(using: .utf8)?.base64EncodedString() {
            UserDefaults.standard.set(auth, forKey: "fm-auth")
        }
    }
    
    // ...
}
```

#### Example: SwiftUI

Set your environment in `MyApp: App`. If you don't see an `init()` function, add one and finish it out like this.

```swift
@main
struct MyApp: App {        
    
    init() {
        let host = "my.host.com"  //
        let db   = "my_database"  //
                                  //  these should be fetched elsewhere, or prompted at launch
        let user = "username"     //
        let pass = "password"     //

        UserDefaults.standard.set(host, forKey: "fm-host")
        UserDefaults.standard.set(db, forKey: "fm-db")
        
        let str = "\(user):\(pass)"
        
        if let auth = str.data(using: .utf8)?.base64EncodedString() {
            UserDefaults.standard.set(auth, forKey: "fm-auth")
        }
    }
    
    var body: some Scene {
        // ...
    }
}
```

---

### ✨ New Session (function) -> .token?

Returns an optional `token`.

If this fails due to an incorrect `Authorization`, the FileMaker Data API will return an error `code` and `message` to the console. All SwiftFM calls output a simple success or failure message.

```swift
func newSession() async -> String? {

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
```

#### Example

```swift
if let token = await SwiftFM.newSession() {
    print("✨ new token » \(token)")
}
```

---

### Validate Session (function) -> Bool

FileMaker Data API 19 or later. Returns a `Bool`. This function isn't all that useful on its own. But you can use it to wrap *other* calls to ensure they're fired with a valid `token`.

```swift
func validateSession(token: String) async -> Bool {

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
```

#### Example

```swift
let isValid = await SwiftFM.validateSession(token: "abcde12345xxxxx")

switch isValid {
case true:
    fetchArtists(token: token)

case false:
    if let newToken = await SwiftFM.newSession() {
       fetchArtists(token: newToken)
    }       
}
```

---


### Delete Session (function) -> @escaping Bool

Returns a `Bool`. For standard Swift (UIKit) apps, a good place to call this would be `applicationDidEnterBackground(_:)`. For SwiftUI apps, you should call it inside a `\.scenePhase.background` switch. 

FileMaker's Data API has a 500-session limit, so managing session tokens will be important for larger deployments. If you don't delete your session token, it ~~will~~ *should* expire 15 minutes after the last API call. Probably. But you should clean up after yourself and not assume this will happen. 🙂

```swift
func deleteSession(token: String, completion: @escaping (Bool) -> Void) {

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
```

#### Example: Swift (UIKit)

```swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
// ...

    func applicationDidEnterBackground(_ application: UIApplication) {
        if let token = UserDefaults.standard.string(forKey: "fm-token") {
            SwiftFM.deleteSession(token: token) { _ in }
        }
    }
    // ...
}
```

#### Example: SwiftUI

```swift
@main
struct MyApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                DispatchQueue.global(qos: .background).async {  // extra time
                    if let token = UserDefaults.standard.string(forKey: "fm-token") {
                        SwiftFM.deleteSession(token: token) { _ in }
                    }                    
                }
            default: break
            }
        }
    }  // .body
}
```

---


### ✨ Create Record (function) -> .recordId?

Returns an optional `recordId`. This can be called with or without a payload. If you set a `nil` payload, a new empty record will be created. Either method will return a `recordId`. Set your payload with a `[String: Any]` object containing a `fieldData` key.

```swift
func createRecord(layout: String, payload: [String: Any]?, token: String) async -> String? {

    var fieldData: [String: Any] = ["fieldData": [:]]  // if nil payload

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
```

#### Example

```swift
let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""
let layout = "Artists"

let payload = ["fieldData": [  // required key
    "firstName": "Brian",
    "lastName": "Hamm",
    "email": "hello@starsite.co"
]]

if let recordId = await SwiftFM.createRecord(layout: layout, payload: payload, token: token) {
    print("created record: \(recordId)")
}
```

---


### Duplicate Record (function) -> .recordId?

FileMaker Data API 18 or later. Pretty simple call. Returns an optional `recordId` for the new record.

```swift
func duplicateRecord(id: Int, layout: String, token: String) async -> String? {

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
```

#### Example

```swift
let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""
let recid  = 12345
let layout = "Artists"

if let recordId = await SwiftFM.duplicateRecord(id: recid, layout: layout, token: token) {
    print("new record: \(recordId)")
}
```

------

### Edit Record (function) -> .modId?

Returns an optional `modId`. Pass a `[String: Any]` object with a `fieldData` key containing the fields you want to modify.

⚠️ If you include the `modId` value in your `payload` (from say, an earlier fetch), the record will only be modified if the `modId` matches the value on FileMaker Server. This ensures you're working with the current version of the record. If you do **not** pass a `modId`, your changes will be applied without this check.

Note: The FileMaker Data API does not pass back a modified record object for you to use. So you might want to refetch the updated record afterward with `getRecord(id:)`.

```swift
func editRecord(id: Int, layout: String, payload: [String: Any], token: String) async -> String? {

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
```

#### Example

```swift
let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""
let recid  = 12345
let layout = "Artists"

let payload = ["fieldData": [
    "address": "My updated address",
]]

if let modId = await SwiftFM.editRecord(id: recid, layout: layout, payload: payload, token: token) {
    print("updated modId: \(modId)")
}
```

---

### 🔥 Delete Record (function) -> Bool

Pretty self explanatory. Returns a `Bool`.

```swift
func deleteRecord(id: Int, layout: String, token: String) async -> Bool {

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
```

#### Example

⚠️ This is Swift, not FileMaker. Nothing will prevent this from firing—immediately. Put some kind of confirmation view in your app.

```swift
let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""
let recid  = 12345
let layout = "Artists"

let result = await SwiftFM.deleteRecord(id: recid, layout: layout, token: token)
    
if result == true {
    print("deleted recordId \(recordId)")
}
```

------

### 🔍 Query (function) -> ([record], .dataInfo)

Returns a `record` array and `dataInfo` response. This is our first function that returns a **tuple**. You can use either object (or both). The `dataInfo` object includes metadata about the request (database, layout, and table; as well as record count values for total, found, and returned). If you want to ignore `dataInfo`, you can assign it an underscore.

You can set your `payload` from the UI, or hardcode a query. Then pass it as a `[String: Any]` object with a `query` key.

```swift
func query(layout: String, payload: [String: Any], token: String) async throws -> (Data, FMResult.DataInfo) {
            
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
        guard   let data     = response["data"] as? [[String: Any]],
                let records  = try? JSONSerialization.data(withJSONObject: data),
                let dataInfo = result.response.dataInfo

        else { throw FMError.jsonSerialization }
        
        print("fetched \(dataInfo.foundCount) records")
        return (records, dataInfo)
        
    default:
        print(message)
        throw FMError.nonZeroCode
    }
}
```

#### Example

Note the difference in payload between an "or" request vs. an "and" request. 

```swift
let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""
let layout = "Artists"

// find artists named Brian or Geoff
let payload = ["query": [
    ["firstName": "Brian"],
    ["firstName": "Geoff"]
]]

// find artists named Brian in Dallas
let payload = ["query": [
    ["firstName": "Brian", "city": "Dallas"]
]]

guard   let (data, _) = try? await SwiftFM.query(layout: layout, payload: payload, token: token),
        let records   = try? JSONDecoder().decode([Artist.Record].self, from: data) 
        
else { return }

self.artists = records  // set @State data source
```

---

### Get Records (function) -> ([record], .dataInfo)

Returns a `record` array and `dataInfo` response. All SwiftFM record fetching methods return a tuple.

```swift
func getRecords(layout: String,
                limit: Int,
                sortField: String,
                ascending: Bool,
                portal: String?,
                token: String) async throws -> (Data, FMResult.DataInfo) {
    
    
    // param str
    let order = ascending ? "ascend" : "descend"
    
    let sortJson = """
    [{"fieldName":"\(sortField)","sortOrder":"\(order)"}]
    """
    
    var portalJson = "[]"     // if nil portal
    
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
        
        print("fetched \(dataInfo.foundCount) records")
        return (records, dataInfo)
        
    default:
        print(message)
        throw FMError.nonZeroCode
    }
}
```

#### Example (SwiftUI)

✨ I'm including a complete SwiftUI example this time, showing the `model`, `view`, and a `fetchArtists(token:)` method. For those unfamiliar with SwiftUI, it's helpful to start in the middle of the example code and work your way out. Here's the gist:

There is a `.task` on `List` which will return data (async) from FileMaker. I'm using that to set our `@State var artists` array. When a `@State` property is modified, any view depending on it will be called again. In our case, this recalls `body`, refreshing `List` with our record data. Neat.

```swift
// model
struct Artist {

    struct Record: Codable {
        let recordId: String    // ✨ useful as a \.keyPath in List views
        let modId: String
        let fieldData: FieldData
    }

    struct FieldData: Codable {
        let name: String      
    }    
}

// view
struct ContentView: View {

    let token = UserDefaults.standard.string(forKey: "fm-token") ?? ""
  
    // our data source
    @State private var artists = [Artist.Record]()
  
    var body: some View {
        NavigationView {
          
            List(artists, id: \.recordId) { artist in
                Text("\(artist.fieldData.name)")    // 🥰 type-safe, Codable properties
            }
            .navigationTitle("Artists")
            .task {  // ✅ <-- start here
                let isValid = await SwiftFM.validateSession(token: token)

                switch isValid {                    
                case true:
                    await fetchArtists(token: token)

                case false:
                    if let newToken = await SwiftFM.newSession() {
                        await fetchArtists(token: newToken)
                    }                        
                }
            }  // .list            
        }
    }
    // ...

    // fetch 20 artists
    func fetchArtists(token: String) async {

        guard   let (data, _) = try? await SwiftFM.getRecords(layout: "Artists", limit: 20, sortField: "name", ascending: true, portal: nil, token: token)
                let records   = try? JSONDecoder().decode([Artist.Record].self, from: data) 
                
        else { return }

        self.artists = records  // sets our @State artists array 👆
    }
    // ...
}
```

- - -


### Get Record (function) -> (record, .dataInfo)

Returns a `record` and `dataInfo` response.

```swift
func getRecord(id: Int, layout: String, token: String) async throws -> (Data, FMResult.DataInfo) {
    
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
```

#### Example

```swift
let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""
let recid  = 12345
let layout = "Artists"

guard   let (data, _) = try? await SwiftFM.getRecord(id: recid, layout: layout, token: token),
        let record    = try? JSONDecoder().decode(Artist.Record.self, from: data) 
        
else { return }

self.artist = record
```

- - -


### Set Globals (function) -> Bool

FileMaker Data API 18 or later. Returns a `Bool`. Make this call with a `[String: Any]` object containing a `globalFields` key.

```swift
func setGlobals(payload: [String: Any], token: String) async -> Bool {

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
```

#### Example

⚠️ Global fields must be set using fully qualified field names, ie. `table name::field name`. Also note that our result is a `Bool` and doesn't need to be unwrapped.

```swift
let token = UserDefaults.standard.string(forKey: "fm-token") ?? ""

let payload = ["globalFields": [
    "baseTable::gField": "newValue",
    "baseTable::gField2": "newValue"
]]

let result = await SwiftFM.setGlobals(payload: payload, token: token)

if result == true {
    print("globals set")
}
```

------

### Get Product Info (function) -> .productInfo?

FileMaker Data API 18 or later. Returns an optional `.productInfo` object.

```swift
func getProductInfo() async -> FMProduct.ProductInfo? {

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
```

#### Example

This call doesn't require a token.

```swift
guard let info = await SwiftFM.getProductInfo() else { return }

print(info.version)  // properties for .name .buildDate, .dateFormat, .timeFormat, and .timeStampFormat
```

------

### Get Databases (function) -> .databases?

FileMaker Data API 18 or later. Returns an optional array of `.database` objects.

```swift
func getDatabases() async -> [FMDatabases.Database]? {

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
```

#### Example

This call doesn't require a token.

```swift
guard let databases = await SwiftFM.getDatabases() else { return }

print("\nDatabases:")
_ = databases.map{ print($0.name) }  // like a .forEach, but shorter
```

------

### Get Layouts (function) -> .layouts?

FileMaker Data API 18 or later. Returns an optional array of `.layout` objects.

```swift
func getLayouts(token: String) async -> [FMLayouts.Layout]? {

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
```

#### Example

Many SwiftFM result types conform to `Comparable`. 🥰  As such, you can use methods like `.sorted()`, `min()`, and `max()`.

```swift
let token = UserDefaults.standard.string(forKey: "fm-token") ?? ""

guard let layouts = await SwiftFM.getLayouts(token: token) else { return }

// filter and sort folders
let folders = layouts.filter{ $0.isFolder == true }.sorted()

folders.forEach { folder in
    print("\n\(folder.name)")

    // tab indent folder contents
    if let items = folder.folderLayoutNames?.sorted() {
        items.forEach { item in
            print("\t\(item.name)")
        }
    }
}
```

------

### Get Layout Metadata (function) -> .response?

FileMaker Data API 18 or later. Returns an optional `.response` object, containing `.fields` and `.valueList` data. A `.portalMetaData` object is included as well, but will be unique to your FileMaker schema. So you'll need to model that yourself.

```swift
func getLayoutMetadata(layout: String, token: String) async -> FMLayoutMetaData.Response? {

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
```

#### Example

```swift
let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""
let layout = "Artists"

guard let result = await SwiftFM.getLayoutMetadata(layout: layout, token: token) else { return }

if let fields = result.fieldMetaData?.sorted() {
    print("\nFields:")
    _ = fields.map { print($0.name) }
}

if let valueLists = result.valueLists?.sorted() {
    print("\nValue Lists:")
    _ = valueLists.map { print($0.name) }
}
```

------

### Get Scripts (function) -> .scripts?

FileMaker Data API 18 or later. Returns an optional array of `.script` objects.

```swift
func getScripts(token: String) async -> [FMScripts.Script]? {

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
```

#### Example

```swift
let token = UserDefaults.standard.string(forKey: "fm-token") ?? ""

guard let scripts = await SwiftFM.getScripts(token: token) else { return }

// filter and sort folders
let folders = scripts.filter{ $0.isFolder == true }.sorted()

folders.forEach { folder in
    print("\n\(folder.name)")

    // tab indent folder contents
    if let scripts = folder.folderScriptNames?.sorted() {
        scripts.forEach { item in
            print("\t\(item.name)")
        }
    }
}
```

------

### Execute Script (function) -> Bool

Returns a `Bool`.

```swift
func executeScript(script: String, parameter: String?, layout: String, token: String) async -> Bool {

    // parameter
    var param = ""  // if nil parameter

    if let parameter = parameter {  // else
        param = parameter
    }

    // encoded
    guard   let scriptEnc = script.urlEncoded,  // StringExtension.swift
            let paramEnc  = param.urlEncoded

    else { return false }

    // url
    guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
            let db   = UserDefaults.standard.string(forKey: "fm-db"),
            let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/script/\(scriptEnc)?script.param=\(paramEnc)")

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
```

#### Example

`Script` and `parameter` values are `.urlEncoded`, so spaces and such are ok.

```swift
let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""
let script = "test script"
let layout = "Artists"

let result = await SwiftFM.executeScript(script: script, parameter: nil, layout: layout, token: token)

if result == true {
    print("fired script: \(script)")
}
```

------

### Set Container (function) -> fileName?

```swift
func setContainer(recordId: Int,
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
    let mimeType = inferType ? fileData.mimeType : "application/octet-stream"  // DataExtension.swift

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
```

#### Example

An `inferType` of `true` will use `DataExtension.swift` (extensions folder) to attempt to set the mime-type automatically. If you don't want this behavior, set `inferType` to `false`, which assigns a default mime-type of "application/octet-stream".

```swift
let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""
let recid  = 12345
let layout = "Artists"
let field  = "headshot"

guard   let url = URL(string: "http://starsite.co/brian_memoji.png"),
        let fileName = await SwiftFM.setContainer(recordId: recid,
                                                  layout: layout,
                                                  container: field,
                                                  filePath: url,
                                                  inferType: true,
                                                  token: token) 
else { return }

print("container set: \(fileName)")
```

------

Starsite Labs 😘
