# SwiftAnthropic - Complete Source Code

This file contains all Swift source files from the SwiftAnthropic repository (https://github.com/jamesrochabrun/SwiftAnthropic).

Repository structure:
- Main source code: Sources/Anthropic/
- Tests: Tests/
- Examples: Examples/
- Package configuration: Package.swift

Total Swift files: 42

---

## Package.swift
```swift
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftAnthropic",
    platforms: [
         .iOS(.v15),
         .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftAnthropic",
            targets: ["SwiftAnthropic"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.25.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftAnthropic",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client", condition: .when(platforms: [.linux])),
            ],
            path: "Sources/Anthropic"),
        .testTarget(
            name: "SwiftAnthropicTests",
            dependencies: ["SwiftAnthropic"]),
    ]
)
```

## Sources/Anthropic/AIProxy/AIProxyCertificatePinning.swift
```swift
//
//  AIProxyCertificatePinning.swift
//
//
//  Created by Lou Zell on 6/23/24.
//

#if !os(Linux)
import Foundation
import OSLog

private let aiproxyLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "UnknownApp",
                                   category: "SwiftAnthropic+AIProxyCertificatePinning")

/// ## About
/// Use this class in conjunction with a URLSession to adopt certificate pinning in your app.
/// Cert pinning greatly reduces the ability for an attacker to snoop on your traffic.
///
/// A common misunderstanding about https is that it's hard for an attacker to read your traffic.
/// Unfortunately, that is only true if you, as the developer, control both sides of the pipe.
/// As an app developer, this is almost never the case. You ship your apps to the app store, and
/// attackers install them. When an attacker has your app on hardware they control (e.g. an iPhone),
/// it is trivial for them to MITM your app and read encrypted traffic.
///
/// Certificate pinning adds an additional layer of security by only allowing the TLS handshake to
/// succeed if your app recognizes the public key from the other side. I have baked in several AIProxy
/// public keys to this implementation.
///
/// This also functions as a reference implementation for any other libraries that want to interact
/// with the aiproxy.pro service using certificate pinning.
///
/// ## Implementor's note, and a gotcha
/// Use an instance of this class as the delegate to URLSession. For example:
///
///     let mySession = URLSession(
///        configuration: .default,
///        delegate: AIProxyCertificatePinningDelegate(),
///        delegateQueue: nil
///     )
///
/// In a perfect world, this would be all that is required of you. In fact, it is all that is required to protect requests made
/// with `await mySession.data(for:)`, because Foundation calls `urlSession:didReceiveChallenge:`
/// internally. However, `await mySession.bytes(for:)` is not protected, which is rather odd. As a workaround,
/// change your callsites from:
///
///     await mySession.bytes(for: request)
///
/// to:
///
///     await mySession.bytes(
///         for: request,
///         delegate: mySession.delegate as? URLSessionTaskDelegate
///     )
///
/// If you encounter other calls in the wild that do not invoke `urlSession:didReceiveChallenge:` on this class,
/// please report them to me.
final class AIProxyCertificatePinningDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
  
  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didReceive challenge: URLAuthenticationChallenge
  ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
    return self.answerChallenge(challenge)
  }
  
  func urlSession(
    _ session: URLSession,
    didReceive challenge: URLAuthenticationChallenge
  ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
    return self.answerChallenge(challenge)
  }
  
  private func answerChallenge(
    _ challenge: URLAuthenticationChallenge
  ) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
    guard let secTrust = challenge.protectionSpace.serverTrust else {
      aiproxyLogger.error("Could not access the server's security space")
      return (.cancelAuthenticationChallenge, nil)
    }
    
    guard let certificate = getServerCert(secTrust: secTrust) else {
      aiproxyLogger.error("Could not access the server's TLS cert")
      return (.cancelAuthenticationChallenge, nil)
    }
    
    let serverPublicKey = SecCertificateCopyKey(certificate)!
    let serverPublicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil)!
    
    for publicKeyData in publicKeysAsData {
      if serverPublicKeyData as Data == publicKeyData {
        let credential = URLCredential(trust: secTrust)
        return (.useCredential, credential)
      }
    }
    return (.cancelAuthenticationChallenge, nil)
  }
}

// MARK: - Private
private var publicKeysAsData: [Data] = {
  let newVal = publicKeysAsHex.map { publicKeyAsHex in
    let keyData = Data(publicKeyAsHex)
    
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
      kSecAttrKeySizeInBits as String: 256
    ]
    
    var error: Unmanaged<CFError>?
    let publicKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error)!
    
    let localPublicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil)! as Data
    
    if let error = error {
      print("Failed to create public key: \(error.takeRetainedValue() as Error)")
      fatalError()
    }
    return localPublicKeyData
  }
  return newVal
}()

private let publicKeysAsHex: [[UInt8]] = [
  // live on api.aiproxy.com
  [
    0x04, 0x4a, 0x42, 0x12, 0xe7, 0xed, 0x36, 0xb4, 0xa9, 0x1f, 0x96, 0x7e, 0xcf, 0xbd, 0xe0,
    0x9d, 0xea, 0x4b, 0xfb, 0xaf, 0xe7, 0xc6, 0x93, 0xf0, 0xbf, 0x92, 0x0f, 0x12, 0x7a, 0x22,
    0x7d, 0x00, 0x77, 0x81, 0xa5, 0x06, 0x26, 0x06, 0x5c, 0x47, 0x8f, 0x57, 0xef, 0x41, 0x39,
    0x0b, 0x3d, 0x41, 0x72, 0x68, 0x33, 0x86, 0x69, 0x14, 0x2a, 0x36, 0x4d, 0x74, 0x7d, 0xbc,
    0x60, 0x91, 0xff, 0xcc, 0x29
  ],

  // live on api.aiproxy.pro
  [
    0x04, 0x25, 0xa2, 0xd1, 0x81, 0xc0, 0x38, 0xce, 0x57, 0xaa, 0x6e, 0xf0, 0x5a, 0xc3, 0x6a,
    0xa7, 0xc4, 0x69, 0x69, 0xcb, 0xeb, 0x24, 0xe5, 0x20, 0x7d, 0x06, 0xcb, 0xc7, 0x49, 0xd5,
    0x0c, 0xac, 0xe6, 0x96, 0xc5, 0xc9, 0x28, 0x00, 0x8e, 0x69, 0xff, 0x9d, 0x32, 0x01, 0x53,
    0x74, 0xab, 0xfd, 0x46, 0x03, 0x32, 0xed, 0x93, 0x7f, 0x0f, 0xe9, 0xd9, 0xc3, 0xaf, 0xe7,
    0xa5, 0xcb, 0xc1, 0x29, 0x35
  ],
  
  // live on beta-api.aiproxy.pro
  [
    0x04, 0xaf, 0xb2, 0xcc, 0xe2, 0x51, 0x92, 0xcf, 0xb8, 0x01, 0x25, 0xc1, 0xb8, 0xda, 0x29,
    0x51, 0x9f, 0x91, 0x4c, 0xaa, 0x09, 0x66, 0x3d, 0x81, 0xd7, 0xad, 0x6f, 0xdb, 0x78, 0x10,
    0xd4, 0xbe, 0xcd, 0x4f, 0xe3, 0xaf, 0x4f, 0xb6, 0xd2, 0xca, 0x85, 0xb6, 0xc7, 0x3e, 0xb4,
    0x61, 0x62, 0xe1, 0xfc, 0x90, 0xd6, 0x84, 0x1f, 0x98, 0xca, 0x83, 0x60, 0x8b, 0x65, 0xcb,
    0x1a, 0x57, 0x6e, 0x32, 0x35,
  ],
  
  // backup-EC-key-A.key
  [
    0x04, 0x2c, 0x25, 0x74, 0xbc, 0x7e, 0x18, 0x10, 0x27, 0xbd, 0x03, 0x56, 0x4a, 0x7b, 0x32,
    0xd2, 0xc1, 0xb0, 0x2e, 0x58, 0x85, 0x9a, 0xb0, 0x7d, 0xcd, 0x7e, 0x23, 0x33, 0x88, 0x2f,
    0xc0, 0xfe, 0xce, 0x2e, 0xbf, 0x36, 0x67, 0xc6, 0x81, 0xf6, 0x52, 0x2b, 0x9b, 0xaf, 0x97,
    0x3c, 0xac, 0x00, 0x39, 0xd8, 0xcc, 0x43, 0x6b, 0x1d, 0x65, 0xa5, 0xad, 0xd1, 0x57, 0x4b,
    0xad, 0xb1, 0x17, 0xd3, 0x10
  ],
  
  // backup-EC-key-B.key
  [
    0x04, 0x34, 0xae, 0x84, 0x94, 0xe9, 0x02, 0xf0, 0x78, 0x0e, 0xee, 0xe6, 0x4e, 0x39, 0x7f,
    0xb4, 0x84, 0xf6, 0xec, 0x55, 0x20, 0x0d, 0x36, 0xe9, 0xa6, 0x44, 0x6b, 0x9b, 0xe1, 0xef,
    0x19, 0xe7, 0x90, 0x5b, 0xf4, 0xa3, 0x29, 0xf3, 0x56, 0x7c, 0x60, 0x97, 0xf0, 0xc6, 0x61,
    0x83, 0x31, 0x5d, 0x2d, 0xc9, 0xcc, 0x40, 0x43, 0xad, 0x81, 0x63, 0xfd, 0xcf, 0xe2, 0x8e,
    0xfa, 0x07, 0x09, 0xf6, 0xf2
  ],
  
  // backup-EC-key-C.key
  [
    0x04, 0x84, 0x4e, 0x33, 0xc8, 0x60, 0xe7, 0x78, 0xaa, 0xa2, 0xb6, 0x0b, 0xcf, 0x7a, 0x52,
    0x43, 0xd1, 0x6d, 0x58, 0xff, 0x17, 0xb8, 0xea, 0x8a, 0x39, 0x53, 0xfb, 0x8b, 0x66, 0x7d,
    0x10, 0x39, 0x80, 0x2c, 0x8d, 0xc9, 0xc3, 0x34, 0x33, 0x98, 0x14, 0xeb, 0x88, 0x7b, 0xf5,
    0x4d, 0x1f, 0x07, 0xae, 0x6a, 0x02, 0x6b, 0xf5, 0x9b, 0xa8, 0xc6, 0x55, 0x5c, 0x27, 0xcd,
    0x1b, 0xc0, 0x27, 0x2d, 0x82
  ]
  
]

private func getServerCert(secTrust: SecTrust) -> SecCertificate? {
  if #available(macOS 12.0, iOS 15.0, *) {
    guard let certs = SecTrustCopyCertificateChain(secTrust) as? [SecCertificate] else {
      return nil
    }
    return certs[0]
  } else {
    return SecTrustGetCertificateAtIndex(secTrust, 0);
  }
}
#endif
```

## Sources/Anthropic/AIProxy/AIProxyService.swift
```swift
//
//  AIProxyService.swift
//
//
//  Created by Lou Zell on 7/31/24.
//

#if !os(Linux)
import Foundation

private let aiproxySecureDelegate = AIProxyCertificatePinningDelegate()


struct AIProxyService: AnthropicService {
  
  let httpClient: HTTPClient
  let decoder: JSONDecoder
  
  /// Your partial key is provided during the integration process at dashboard.aiproxy.pro
  /// Please see the [integration guide](https://www.aiproxy.pro/docs/integration-guide.html) for acquiring your partial key
  private let partialKey: String
  
  /// Your service URL is also provided during the integration process.
  private let serviceURL: String
  
  /// Optionally supply your own client IDs to annotate requests with in the AIProxy developer dashboard.
  /// It is safe to leave this blank (most people do). If you leave it blank, AIProxy generates client IDs for you.
  private let clientID: String?
  
  /// Set this flag to TRUE if you need to print request events in DEBUG builds.
  private let debugEnabled: Bool
  
  /// Defaults to "2023-06-01"
  private var apiVersion: String
  
  private let betaHeaders: [String]?
  
  init(
    partialKey: String,
    serviceURL: String,
    clientID: String? = nil,
    apiVersion: String = "2023-06-01",
    betaHeaders: [String]?,
    debugEnabled: Bool)
  {
    let decoderWithSnakeCaseStrategy = JSONDecoder()
    decoderWithSnakeCaseStrategy.keyDecodingStrategy = .convertFromSnakeCase
    self.decoder = decoderWithSnakeCaseStrategy
    self.partialKey = partialKey
    self.serviceURL = serviceURL
    self.clientID = clientID
    self.apiVersion = apiVersion
    self.betaHeaders = betaHeaders
    self.debugEnabled = debugEnabled
    self.httpClient = URLSessionHTTPClientAdapter(
      urlSession: URLSession(
        configuration: .default,
        delegate: aiproxySecureDelegate,
        delegateQueue: nil
      )
    )
  }
  
  // MARK: Message
  
  func createMessage(
    _ parameter: MessageParameter)
  async throws -> MessageResponse
  {
    var localParameter = parameter
    localParameter.stream = false
    let request = try await AnthropicAPI(base: serviceURL, apiPath: .messages).request(aiproxyPartialKey: partialKey, clientID: clientID, version: apiVersion, method: .post, params: localParameter, betaHeaders: betaHeaders)
    return try await fetch(type: MessageResponse.self, with: request, debugEnabled: debugEnabled)
  }
  
  func streamMessage(
    _ parameter: MessageParameter)
  async throws -> AsyncThrowingStream<MessageStreamResponse, Error>
  {
    var localParameter = parameter
    localParameter.stream = true
    let request = try await AnthropicAPI(base: serviceURL, apiPath: .messages).request(aiproxyPartialKey: partialKey, clientID: clientID, version: apiVersion, method: .post, params: localParameter, betaHeaders: betaHeaders)
    return try await fetchStream(type: MessageStreamResponse.self, with: request, debugEnabled: debugEnabled)
  }
  
  func countTokens(
    parameter: MessageTokenCountParameter)
  async throws -> MessageInputTokens
  {
    let request = try await AnthropicAPI(base: serviceURL, apiPath: .countTokens).request(aiproxyPartialKey: partialKey, clientID: clientID, version: apiVersion, method: .post, params: parameter, betaHeaders: betaHeaders)
    return try await fetch(type: MessageInputTokens.self, with: request, debugEnabled: debugEnabled)
  }
  
  // MARK: Text Completion
  
  func createTextCompletion(
    _ parameter: TextCompletionParameter)
  async throws -> TextCompletionResponse
  {
    var localParameter = parameter
    localParameter.stream = false
    let request = try await AnthropicAPI(base: serviceURL, apiPath: .textCompletions).request(aiproxyPartialKey: partialKey, clientID: clientID, version: apiVersion, method: .post, params: localParameter)
    return try await fetch(type: TextCompletionResponse.self, with: request, debugEnabled: debugEnabled)
  }
  
  func createStreamTextCompletion(
    _ parameter: TextCompletionParameter)
  async throws -> AsyncThrowingStream<TextCompletionStreamResponse, Error>
  {
    var localParameter = parameter
    localParameter.stream = true
    let request = try await AnthropicAPI(base: serviceURL, apiPath: .textCompletions).request(aiproxyPartialKey: partialKey, clientID: clientID, version: apiVersion, method: .post, params: localParameter)
    return try await fetchStream(type: TextCompletionStreamResponse.self, with: request, debugEnabled: debugEnabled)
  }
}
#endif
```

## Sources/Anthropic/AIProxy/Endpoint+AIProxy.swift
```swift
//
//  Endpoint+AIProxy.swift
//
//
//  Created by Lou Zell on 3/26/24.
//

#if !os(Linux)
import Foundation
import OSLog
import DeviceCheck
#if canImport(UIKit)
import UIKit
#endif
#if canImport(IOKit)
import IOKit
#endif
#if os(watchOS)
import WatchKit
#endif

private let aiproxyLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "UnknownApp",
                                   category: "SwiftAnthropic+AIProxy")

private let deviceCheckWarning = """
    AIProxy warning: DeviceCheck is not available on this device.
    
    To use AIProxy on an iOS simulator, set an AIPROXY_DEVICE_CHECK_BYPASS environment variable.
    
    See the AIProxy section of the README at https://github.com/jamesrochabrun/SwiftAnthropic for instructions.
    """


// MARK: Endpoint+AIProxy
extension Endpoint {
  
  func request(
    aiproxyPartialKey: String,
    clientID: String?,
    version: String,
    method: HTTPMethod,
    params: Encodable? = nil,
    betaHeaders: [String]? = nil,
    queryItems: [URLQueryItem] = [])
  async throws -> URLRequest
  {
    var request = URLRequest(url: urlComponents(queryItems: queryItems).url!)
    
    request.addValue(aiproxyPartialKey, forHTTPHeaderField: "aiproxy-partial-key")
    if let clientID = clientID ?? getClientID() {
      request.addValue(clientID, forHTTPHeaderField: "aiproxy-client-id")
    }
    if let deviceCheckToken = await getDeviceCheckToken() {
      request.addValue(deviceCheckToken, forHTTPHeaderField: "aiproxy-devicecheck")
    }
#if DEBUG && targetEnvironment(simulator)
    if let deviceCheckBypass = ProcessInfo.processInfo.environment["AIPROXY_DEVICE_CHECK_BYPASS"] {
      request.addValue(deviceCheckBypass, forHTTPHeaderField: "aiproxy-devicecheck-bypass")
    }
#endif
    
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("\(version)", forHTTPHeaderField: "anthropic-version")
    if let betaHeaders {
      request.addValue("\(betaHeaders.joined(separator: ","))", forHTTPHeaderField: "anthropic-beta")
    }
    request.httpMethod = method.rawValue
    if let params {
      let encoder = JSONEncoder()
      encoder.keyEncodingStrategy = .convertToSnakeCase
      request.httpBody = try encoder.encode(params)
    }
    return request
  }
}


// MARK: Private Helpers

/// Gets a device check token for use in your calls to aiproxy.
/// The device token may be nil when targeting the iOS simulator.
private func getDeviceCheckToken() async -> String? {
  guard DCDevice.current.isSupported else {
    if ProcessInfo.processInfo.environment["AIPROXY_DEVICE_CHECK_BYPASS"] == nil {
      aiproxyLogger.warning("\(deviceCheckWarning, privacy: .public)")
    }
    return nil
  }
  
  do {
    let data = try await DCDevice.current.generateToken()
    return data.base64EncodedString()
  } catch {
    aiproxyLogger.error("Could not create DeviceCheck token. Are you using an explicit bundle identifier?")
    return nil
  }
}

/// Get a unique ID for this client
private func getClientID() -> String? {
#if os(watchOS)
  return WKInterfaceDevice.current().identifierForVendor?.uuidString
#elseif canImport(UIKit)
  return UIDevice.current.identifierForVendor?.uuidString
#elseif canImport(IOKit)
  return getIdentifierFromIOKit()
#else
  return nil
#endif
}


// MARK: IOKit conditional dependency
/// These functions are used on macOS for creating a client identifier.
/// Unfortunately, macOS does not have a straightforward helper like UIKit's `identifierForVendor`
#if canImport(IOKit)
private func getIdentifierFromIOKit() -> String? {
  guard let macBytes = copy_mac_address() as? Data else {
    return nil
  }
  let macHex = macBytes.map { String(format: "%02X", $0) }
  return macHex.joined(separator: ":")
}

// This function is taken from the Apple sample code at:
// https://developer.apple.com/documentation/appstorereceipts/validating_receipts_on_the_device#3744656
private func io_service(named name: String, wantBuiltIn: Bool) -> io_service_t? {
  let default_port = kIOMainPortDefault
  var iterator = io_iterator_t()
  defer {
    if iterator != IO_OBJECT_NULL {
      IOObjectRelease(iterator)
    }
  }
  
  guard let matchingDict = IOBSDNameMatching(default_port, 0, name),
        IOServiceGetMatchingServices(default_port,
                                     matchingDict as CFDictionary,
                                     &iterator) == KERN_SUCCESS,
        iterator != IO_OBJECT_NULL
  else {
    return nil
  }
  
  var candidate = IOIteratorNext(iterator)
  while candidate != IO_OBJECT_NULL {
    if let cftype = IORegistryEntryCreateCFProperty(candidate,
                                                    "IOBuiltin" as CFString,
                                                    kCFAllocatorDefault,
                                                    0) {
      let isBuiltIn = cftype.takeRetainedValue() as! CFBoolean
      if wantBuiltIn == CFBooleanGetValue(isBuiltIn) {
        return candidate
      }
    }
    
    IOObjectRelease(candidate)
    candidate = IOIteratorNext(iterator)
  }
  
  return nil
}

// This function is taken from the Apple sample code at:
// https://developer.apple.com/documentation/appstorereceipts/validating_receipts_on_the_device#3744656
private func copy_mac_address() -> CFData? {
  // Prefer built-in network interfaces.
  // For example, an external Ethernet adaptor can displace
  // the built-in Wi-Fi as en0.
  guard let service = io_service(named: "en0", wantBuiltIn: true)
          ?? io_service(named: "en1", wantBuiltIn: true)
          ?? io_service(named: "en0", wantBuiltIn: false)
  else { return nil }
  defer { IOObjectRelease(service) }
  
  if let cftype = IORegistryEntrySearchCFProperty(
    service,
    kIOServicePlane,
    "IOMACAddress" as CFString,
    kCFAllocatorDefault,
    IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)) {
    return (cftype as! CFData)
  }
  
  return nil
}
#endif
#endif
```

## Sources/Anthropic/Private/Network/AnthropicAPI.swift
```swift
//
//  AnthropicAPI.swift
//
//
//  Created by James Rochabrun on 1/28/24.
//

import Foundation

// MARK: AnthropicAPI

struct AnthropicAPI {
  
  let base: String
  let apiPath: APIPath
  
  enum APIPath {
    case messages
    case textCompletions
    case countTokens
  }
}

// MARK: AnthropicAPI+Endpoint

extension AnthropicAPI: Endpoint {
  
  var path: String {
    switch apiPath {
    case .messages: return "/v1/messages"
    case .countTokens: return "/v1/messages/count_tokens"
    case .textCompletions: return "/v1/complete"
    }
  }
}
```

## Sources/Anthropic/Private/Network/Endpoint.swift
```swift
//
//  Endpoint.swift
//
//
//  Created by James Rochabrun on 1/28/24.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: HTTPMethod

public enum HTTPMethod: String {
  case post = "POST"
  case get = "GET"
  case delete = "DELETE"
}

// MARK: Endpoint

protocol Endpoint {
  
  var base: String { get }
  var path: String { get }
}

// MARK: Endpoint+Requests

extension Endpoint {
  
  func urlComponents(
    queryItems: [URLQueryItem])
  -> URLComponents
  {
    var components = URLComponents(string: base)!
    components.path = components.path.appending(path)
    if !queryItems.isEmpty {
      components.queryItems = queryItems
    }
    return components
  }
  
  /*
   curl -X POST https://api.anthropic.com/v1/messages \
   --header "x-api-key: $ANTHROPIC_API_KEY" \
   --header "anthropic-version: 2023-06-01" \
   --header "anthropic-beta: messages-2023-12-15" \
   --header "content-type: application/json" \
   --data \
   '{
   "model": "claude-2.1",
   "max_tokens": 1024,
   "messages": [
   {"role": "user", "content": "Hello, Claude"}
   ]
   }'
   */
  func request(
    apiKey: String,
    version: String,
    method: HTTPMethod,
    params: Encodable? = nil,
    betaHeaders: [String]? = nil,
    queryItems: [URLQueryItem] = [])
  throws -> URLRequest
  {
    var request = URLRequest(url: urlComponents(queryItems: queryItems).url!)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("\(apiKey)", forHTTPHeaderField: "x-api-key")
    request.addValue("\(version)", forHTTPHeaderField: "anthropic-version")
    if let betaHeaders {
      request.addValue("\(betaHeaders.joined(separator: ","))", forHTTPHeaderField: "anthropic-beta")
    }
    request.httpMethod = method.rawValue
    if let params {
      let encoder = JSONEncoder()
      encoder.keyEncodingStrategy = .convertToSnakeCase
      request.httpBody = try encoder.encode(params)
    }
    return request
  }
}
```

## Sources/Anthropic/Private/Networking/AsyncHTTPClientAdapter.swift
```swift
//
//  AsyncHTTPClientAdapter.swift
//  SwiftAnthropic
//
//  Created by Joe Fabisevich on 5/18/25.
//

#if os(Linux)
import AsyncHTTPClient
import Foundation
import NIOCore
import NIOFoundationCompat
import NIOHTTP1

/// Adapter that implements HTTPClient protocol using AsyncHTTPClient
public class AsyncHTTPClientAdapter: HTTPClient {
  /// Initializes a new AsyncHTTPClientAdapter with the provided AsyncHTTPClient
  /// - Parameter client: The AsyncHTTPClient instance to use
  public init(client: AsyncHTTPClient.HTTPClient) {
    self.client = client
  }

  deinit {
    shutdown()
  }

  /// Creates a new AsyncHTTPClientAdapter with a default configuration
  /// - Returns: A new AsyncHTTPClientAdapter instance
  public static func createDefault() -> AsyncHTTPClientAdapter {
    let httpClient = AsyncHTTPClient.HTTPClient(
      eventLoopGroupProvider: .singleton,
      configuration: AsyncHTTPClient.HTTPClient.Configuration(
        certificateVerification: .fullVerification,
        timeout: .init(
          connect: .seconds(30),
          read: .seconds(30)),
        backgroundActivityLogger: nil))
    return AsyncHTTPClientAdapter(client: httpClient)
  }

  /// Fetches data for a given HTTP request
  /// - Parameter request: The HTTP request to perform
  /// - Returns: A tuple containing the data and HTTP response
  public func data(for request: HTTPRequest) async throws -> (Data, HTTPResponse) {
    let asyncHTTPClientRequest = try createAsyncHTTPClientRequest(from: request)

    let response = try await client.execute(asyncHTTPClientRequest, deadline: .now() + .seconds(60))
    let body = try await response.body.collect(upTo: 100 * 1024 * 1024) // 100 MB max

    let data = Data(buffer: body)
    let httpResponse = HTTPResponse(
      statusCode: Int(response.status.code),
      headers: convertHeaders(response.headers))

    return (data, httpResponse)
  }

  /// Fetches a byte stream for a given HTTP request
  /// - Parameter request: The HTTP request to perform
  /// - Returns: A tuple containing the byte stream and HTTP response
  public func bytes(for request: HTTPRequest) async throws -> (HTTPByteStream, HTTPResponse) {
    let asyncHTTPClientRequest = try createAsyncHTTPClientRequest(from: request)

    let response = try await client.execute(asyncHTTPClientRequest, deadline: .now() + .seconds(60))
    let httpResponse = HTTPResponse(
      statusCode: Int(response.status.code),
      headers: convertHeaders(response.headers))

    let stream = AsyncThrowingStream<String, Error> { continuation in
      Task {
        do {
          for try await byteBuffer in response.body {
            if let string = byteBuffer.getString(at: 0, length: byteBuffer.readableBytes) {
              let lines = string.split(separator: "\n", omittingEmptySubsequences: false)
              for line in lines {
                continuation.yield(String(line))
              }
            }
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }

    return (.lines(stream), httpResponse)
  }

  /// Properly shutdown the HTTP client
  public func shutdown() {
    try? client.shutdown().wait()
  }

  /// The underlying AsyncHTTPClient instance
  private let client: AsyncHTTPClient.HTTPClient

  /// Converts our HTTPRequest to AsyncHTTPClient's Request
  /// - Parameter request: Our HTTPRequest
  /// - Returns: AsyncHTTPClient Request
  private func createAsyncHTTPClientRequest(from request: HTTPRequest) throws -> HTTPClientRequest {
    var asyncHTTPClientRequest = HTTPClientRequest(url: request.url.absoluteString)
    asyncHTTPClientRequest.method = NIOHTTP1.HTTPMethod(rawValue: request.method.rawValue)

    // Add headers
    for (key, value) in request.headers {
      asyncHTTPClientRequest.headers.add(name: key, value: value)
    }

    // Add body if present
    if let body = request.body {
      asyncHTTPClientRequest.body = .bytes(body)
    }

    return asyncHTTPClientRequest
  }

  /// Converts NIOHTTP1 headers to a dictionary
  /// - Parameter headers: NIOHTTP1 HTTPHeaders
  /// - Returns: Dictionary of header name-value pairs
  private func convertHeaders(_ headers: HTTPHeaders) -> [String: String] {
    var result = [String: String]()
    for header in headers {
      result[header.name] = header.value
    }
    return result
  }

}
#endif```

## Sources/Anthropic/Private/Networking/HTTPClient.swift
```swift
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - HTTPClient

/// Protocol that abstracts HTTP client functionality
public protocol HTTPClient {
  /// Fetches data for a given HTTP request
  /// - Parameter request: The HTTP request to perform
  /// - Returns: A tuple containing the data and HTTP response
  func data(for request: HTTPRequest) async throws -> (Data, HTTPResponse)

  /// Fetches a byte stream for a given HTTP request
  /// - Parameter request: The HTTP request to perform
  /// - Returns: A tuple containing the byte stream and HTTP response
  func bytes(for request: HTTPRequest) async throws -> (HTTPByteStream, HTTPResponse)
}

// MARK: - HTTPRequest

/// Represents an HTTP request with platform-agnostic properties
public struct HTTPRequest {
  public init(url: URL, method: HTTPMethod, headers: [String: String], body: Data? = nil) {
    self.url = url
    self.method = method
    self.headers = headers
    self.body = body
  }

  /// Initializes an HTTPRequest from a URLRequest
  /// - Parameter urlRequest: The URLRequest to convert
  public init(from urlRequest: URLRequest) throws {
    guard let url = urlRequest.url else {
      throw URLError(.badURL)
    }

    guard
      let httpMethodString = urlRequest.httpMethod,
      let httpMethod = HTTPMethod(rawValue: httpMethodString)
    else {
      throw URLError(.unsupportedURL)
    }

    var headers: [String: String] = [:]
    if let allHTTPHeaderFields = urlRequest.allHTTPHeaderFields {
      headers = allHTTPHeaderFields
    }

    self.url = url
    method = httpMethod
    self.headers = headers
    body = urlRequest.httpBody
  }

  /// The URL for the request
  var url: URL
  /// The HTTP method for the request
  var method: HTTPMethod
  /// The HTTP headers for the request
  var headers: [String: String]
  /// The body of the request, if any
  var body: Data?

}

// MARK: - HTTPResponse

/// Represents an HTTP response with platform-agnostic properties
public struct HTTPResponse {
  /// The HTTP status code of the response
  var statusCode: Int
  /// The HTTP headers in the response
  var headers: [String: String]

  public init(statusCode: Int, headers: [String: String]) {
    self.statusCode = statusCode
    self.headers = headers
  }
}

// MARK: - HTTPByteStream

/// Represents a stream of bytes or lines from an HTTP response
public enum HTTPByteStream {
  /// A stream of bytes
  case bytes(AsyncThrowingStream<UInt8, Error>)
  /// A stream of lines (strings)
  case lines(AsyncThrowingStream<String, Error>)
}

// MARK: - HTTPClientFactory

public enum HTTPClientFactory {
  /// Creates a default HTTPClient implementation appropriate for the current platform
  /// - Returns: URLSessionHTTPClientAdapter on Apple platforms, AsyncHTTPClientAdapter on Linux
  public static func createDefault() -> HTTPClient {
    #if os(Linux)
    return AsyncHTTPClientAdapter.createDefault()
    #else
    return URLSessionHTTPClientAdapter()
    #endif
  }
}```

## Sources/Anthropic/Private/Networking/URLSessionHTTPClientAdapter.swift
```swift
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if !os(Linux)
/// Adapter that implements HTTPClient protocol using URLSession
public class URLSessionHTTPClientAdapter: HTTPClient {

  /// Initializes a new URLSessionHTTPClientAdapter with the provided URLSession
  /// - Parameter urlSession: The URLSession instance to use. Defaults to `URLSession.shared`.
  public init(urlSession: URLSession = .shared) {
    self.urlSession = urlSession
  }

  /// Fetches data for a given HTTP request
  /// - Parameter request: The HTTP request to perform
  /// - Returns: A tuple containing the data and HTTP response
  public func data(for request: HTTPRequest) async throws -> (Data, HTTPResponse) {
    let urlRequest = try createURLRequest(from: request)

    let (data, urlResponse) = try await urlSession.data(for: urlRequest)

    guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
      throw URLError(.badServerResponse) // Or a custom error
    }

    let response = HTTPResponse(
      statusCode: httpURLResponse.statusCode,
      headers: convertHeaders(httpURLResponse.allHeaderFields))

    return (data, response)
  }

  /// Fetches a byte stream for a given HTTP request
  /// - Parameter request: The HTTP request to perform
  /// - Returns: A tuple containing the byte stream and HTTP response
  public func bytes(for request: HTTPRequest) async throws -> (HTTPByteStream, HTTPResponse) {
    let urlRequest = try createURLRequest(from: request)

    let (asyncBytes, urlResponse) = try await urlSession.bytes(for: urlRequest)

    guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
      throw URLError(.badServerResponse) // Or a custom error
    }

    let response = HTTPResponse(
      statusCode: httpURLResponse.statusCode,
      headers: convertHeaders(httpURLResponse.allHeaderFields))

    let stream = AsyncThrowingStream<String, Error> { continuation in
      Task {
        do {
          for try await line in asyncBytes.lines {
            continuation.yield(line)
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }

    return (.lines(stream), response)
  }

  private let urlSession: URLSession

  /// Converts our HTTPRequest to URLRequest
  /// - Parameter request: Our HTTPRequest
  /// - Returns: URLRequest
  private func createURLRequest(from request: HTTPRequest) throws -> URLRequest {
    var urlRequest = URLRequest(url: request.url)
    urlRequest.httpMethod = request.method.rawValue

    for (key, value) in request.headers {
      urlRequest.setValue(value, forHTTPHeaderField: key)
    }

    urlRequest.httpBody = request.body

    return urlRequest
  }

  /// Converts HTTPURLResponse headers to a dictionary [String: String]
  /// - Parameter headers: The headers from HTTPURLResponse (i.e. `allHeaderFields`)
  /// - Returns: Dictionary of header name-value pairs
  private func convertHeaders(_ headers: [AnyHashable: Any]) -> [String: String] {
    var result = [String: String]()
    for (key, value) in headers {
      if let keyString = key as? String, let valueString = value as? String {
        result[keyString] = valueString
      }
    }
    return result
  }
}
#endif```

## Sources/Anthropic/Public/Model.swift
```swift
//
//  Model.swift
//
//
//  Created by James Rochabrun on 2/24/24.
//

import Foundation

/// Currently available models
/// We currently offer two families of models:
///
/// - Claude Instant: low-latency, high throughput.
/// - Claude: superior performance on tasks that require complex reasoning.
///
/// See our pricing page for pricing details.
///
/// When making requests to APIs, you must specify the model to perform the completion using the model parameter.
///
/// API model name          Model family
/// - claude-instant-1.2    Claude Instant
/// - claude-2.1                Claude
/// - claude-2.0                Claude
/// 
/// Anthropic offer two families of models:
///
/// *Claude Instant:* low-latency, high throughput.
/// *Claude:* superior performance on tasks that require complex reasoning.
///
/// When making requests to APIs, you must specify the model to perform the completion using the model parameter.
///
/// Family   Latest version
/// Claude Instant   claude-instant-1.2
/// Claude   claude-2.1
/// Note that we previously supported specifying only the major version number, e.g., claude-2, which would result in new minor versions being used automatically as they are released. However, we no longer recommend this integration pattern, and the new Messages API does not support it.
///
/// Each model has a maximum total context window size and a maximum completion length.
///
/// Model   Context window size   Max completion length
/// claude-2.1   200,000 tokens   4,096 tokens
/// claude-2.0   100,000 tokens   4,096 tokens
/// claude-instant-1.2   100,000 tokens   4,096 tokens
/// The total context window size includes both the request prompt length and response completion length. If the prompt length approaches the context window size, the max output length will be reduced to fit within the context window size.
///
/// If you encounter "stop_reason": "max_tokens" in a completion response and want Claude to continue from where it left off, you can make a new request with the previous completion appended to the previous prompt.

/// [More](https://docs.anthropic.com/claude/reference/selecting-a-model)
/// [Models](https://docs.anthropic.com/en/docs/about-claude/models)
public enum Model {
   
   case claudeInstant12
   case claude2 
   case claude21
   case claude3Opus
   case claude3Sonnet
   case claude35Sonnet
   case claude3Haiku
   case claude35Haiku
   case claude37Sonnet
   
   case other(String)

   public var value: String {
      switch self {
      case .claudeInstant12: return "claude-instant-1.2"
      case .claude2: return "claude-2.0"
      case .claude21: return "claude-2.1"
      case .claude3Opus: return "claude-3-opus-20240229"
      case .claude3Sonnet: return "claude-3-sonnet-20240229"
      case .claude35Sonnet: return "claude-3-5-sonnet-latest"
      case .claude3Haiku: return "claude-3-haiku-20240307"
      case .claude35Haiku: return "claude-3-5-haiku-latest"
      case .claude37Sonnet: return "claude-3-7-sonnet-latest"
      case .other(let model): return model
      }
   }
}
```

## Sources/Anthropic/Public/Parameters/Message/JSONSchema.swift
```swift
//
//  JSONSchema.swift
//  SwiftAnthropic
//
//  Created by James Rochabrun on 3/16/25.
//

import Foundation

public struct JSONSchema: Codable, Equatable {
   
   public let type: JSONType
   public let properties: [String: Property]?
   public let required: [String]?
   public let pattern: String?
   public let const: String?
   public let enumValues: [String]?
   public let multipleOf: Int?
   public let minimum: Int?
   public let maximum: Int?
   
   private enum CodingKeys: String, CodingKey {
      case type, properties, required, pattern, const
      case enumValues = "enum"
      case multipleOf, minimum, maximum
   }
   
   public struct Property: Codable, Equatable {
      
      public let type: JSONType
      public let description: String?
      public let format: String?
      public let items: Items?
      public let required: [String]?
      public let pattern: String?
      public let const: String?
      public let enumValues: [String]?
      public let multipleOf: Int?
      public let minimum: Double?
      public let maximum: Double?
      public let minItems: Int?
      public let maxItems: Int?
      public let uniqueItems: Bool?
      
      private enum CodingKeys: String, CodingKey {
         case type, description, format, items, required, pattern, const
         case enumValues = "enum"
         case multipleOf, minimum, maximum
         case minItems, maxItems, uniqueItems
      }
      
      public init(
         type: JSONType,
         description: String? = nil,
         format: String? = nil,
         items: Items? = nil,
         required: [String]? = nil,
         pattern: String? = nil,
         const: String? = nil,
         enumValues: [String]? = nil,
         multipleOf: Int? = nil,
         minimum: Double? = nil,
         maximum: Double? = nil,
         minItems: Int? = nil,
         maxItems: Int? = nil,
         uniqueItems: Bool? = nil)
      {
         self.type = type
         self.description = description
         self.format = format
         self.items = items
         self.required = required
         self.pattern = pattern
         self.const = const
         self.enumValues = enumValues
         self.multipleOf = multipleOf
         self.minimum = minimum
         self.maximum = maximum
         self.minItems = minItems
         self.maxItems = maxItems
         self.uniqueItems = uniqueItems
      }
   }
   
   public enum JSONType: String, Codable {
      case integer = "integer"
      case string = "string"
      case boolean = "boolean"
      case array = "array"
      case object = "object"
      case number = "number"
      case `null` = "null"
   }
   
   public struct Items: Codable, Equatable {
      
      public let type: JSONType
      public let properties: [String: Property]?
      public let pattern: String?
      public let const: String?
      public let enumValues: [String]?
      public let multipleOf: Int?
      public let minimum: Double?
      public let maximum: Double?
      public let minItems: Int?
      public let maxItems: Int?
      public let uniqueItems: Bool?
      
      private enum CodingKeys: String, CodingKey {
         case type, properties, pattern, const
         case enumValues = "enum"
         case multipleOf, minimum, maximum, minItems, maxItems, uniqueItems
      }
      
      public init(
         type: JSONType,
         properties: [String : Property]? = nil,
         pattern: String? = nil,
         const: String? = nil,
         enumValues: [String]? = nil,
         multipleOf: Int? = nil,
         minimum: Double? = nil,
         maximum: Double? = nil,
         minItems: Int? = nil,
         maxItems: Int? = nil,
         uniqueItems: Bool? = nil)
      {
         self.type = type
         self.properties = properties
         self.pattern = pattern
         self.const = const
         self.enumValues = enumValues
         self.multipleOf = multipleOf
         self.minimum = minimum
         self.maximum = maximum
         self.minItems = minItems
         self.maxItems = maxItems
         self.uniqueItems = uniqueItems
      }
   }
   
   public init(
      type: JSONType,
      properties: [String : Property]? = nil,
      required: [String]? = nil,
      pattern: String? = nil,
      const: String? = nil,
      enumValues: [String]? = nil,
      multipleOf: Int? = nil,
      minimum: Int? = nil,
      maximum: Int? = nil)
   {
      self.type = type
      self.properties = properties
      self.required = required
      self.pattern = pattern
      self.const = const
      self.enumValues = enumValues
      self.multipleOf = multipleOf
      self.minimum = minimum
      self.maximum = maximum
   }
}
```

## Sources/Anthropic/Public/Parameters/Message/MessageParameter+Web.swift
```swift
//
//  MessageParameter+Web.swift
//  SwiftAnthropic
//
//  Created by James Rochabrun on 5/12/25.
//

import Foundation

public extension MessageParameter {
   
   /// Creates a web search tool with default configuration
   static func webSearch(
      name: String = "web_search",
      maxUses: Int? = nil
   ) -> Tool {
      let parameters = WebSearchParameters(maxUses: maxUses)
      return .webSearch(name: name, parameters: parameters)
   }
   
   /// Creates a web search tool with domain filtering
   static func webSearch(
      name: String = "web_search",
      maxUses: Int? = nil,
      allowedDomains: [String]? = nil,
      blockedDomains: [String]? = nil
   ) -> Tool {
      let parameters = WebSearchParameters(
         maxUses: maxUses,
         allowedDomains: allowedDomains,
         blockedDomains: blockedDomains
      )
      return .webSearch(name: name, parameters: parameters)
   }
   
   /// Creates a web search tool with user location for localized results
   static func webSearch(
      name: String = "web_search",
      maxUses: Int? = nil,
      userLocation: UserLocation
   ) -> Tool {
      let parameters = WebSearchParameters(
         maxUses: maxUses,
         userLocation: userLocation
      )
      return .webSearch(name: name, parameters: parameters)
   }
   
   /// Creates a web search tool with full configuration
   static func webSearch(
      name: String = "web_search",
      maxUses: Int? = nil,
      allowedDomains: [String]? = nil,
      blockedDomains: [String]? = nil,
      userLocation: UserLocation? = nil
   ) -> Tool {
      let parameters = WebSearchParameters(
         maxUses: maxUses,
         allowedDomains: allowedDomains,
         blockedDomains: blockedDomains,
         userLocation: userLocation
      )
      return .webSearch(name: name, parameters: parameters)
   }
   
   /// Creates a location for a US city
   static func usCity(
      city: String,
      region: String,
      timezone: String
   ) -> UserLocation {
      return UserLocation(
         type: .approximate,
         city: city,
         region: region,
         country: "US",
         timezone: timezone
      )
   }
}

public extension MessageParameter.UserLocation {
   
   /// Common US locations
   static let sanFrancisco = Self(
      type: .approximate,
      city: "San Francisco",
      region: "California",
      country: "US",
      timezone: "America/Los_Angeles"
   )
   
   static let newYork = Self(
      type: .approximate,
      city: "New York",
      region: "New York",
      country: "US",
      timezone: "America/New_York"
   )
   
   static let chicago = Self(
      type: .approximate,
      city: "Chicago",
      region: "Illinois",
      country: "US",
      timezone: "America/Chicago"
   )
}
```

## Sources/Anthropic/Public/Parameters/Message/MessageParameter.swift
```swift
//
//  MessageParameter.swift
//
//
//  Created by James Rochabrun on 1/28/24.
//

import Foundation

/*
 Create a Message.
 Send a structured list of input messages, and the model will generate the next message in the conversation.
 Messages can be used for either single queries to the model or for multi-turn conversations.
 The Messages API is currently in beta. During beta, you must send the anthropic-beta: messages-2023-12-15 header in your requests. If you are using our client SDKs, this is handled for you automatically.
 */


/// [Create a message.](https://docs.anthropic.com/claude/reference/messages_post)
///  POST -  https://api.anthropic.com/v1/messages
public struct MessageParameter: Encodable {
   
   /// The model that will complete your prompt.
   // As we improve Claude, we develop new versions of it that you can query. The model parameter controls which version of Claude responds to your request. Right now we offer two model families: Claude, and Claude Instant. You can use them by setting model to "claude-2.1" or "claude-instant-1.2", respectively.
   /// See [models](https://docs.anthropic.com/claude/reference/selecting-a-model) for additional details and options.
   public let model: String
   
   /// Input messages.
   /// Our models are trained to operate on alternating user and assistant conversational turns. When creating a new Message, you specify the prior conversational turns with the messages parameter, and the model then generates the next Message in the conversation.
   /// Each input message must be an object with a role and content. You can specify a single user-role message, or you can include multiple user and assistant messages. The first message must always use the user role.
   /// If the final message uses the assistant role, the response content will continue immediately from the content in that message. This can be used to constrain part of the model's response.
   public let messages: [Message]
   
   /// The maximum number of tokens to generate before stopping.
   /// Note that our models may stop before reaching this maximum. This parameter only specifies the absolute maximum number of tokens to generate.
   /// Different models have different maximum values for this parameter. See [input and output](https://docs.anthropic.com/claude/reference/input-and-output-sizes) sizes for details.
   public let maxTokens: Int
   
   /// System prompt.
   /// A system prompt is a way of providing context and instructions to Claude, such as specifying a particular goal or role. See our [guide to system prompts](https://docs.anthropic.com/claude/docs/how-to-use-system-prompts).
   /// System role can be either a simple String or an array of objects, use the objects array for prompt caching.
   /// [Prompt Caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
   public let system: System?
   
   /// An object describing metadata about the request.
   public let metadata: MetaData?
   
   /// Custom text sequences that will cause the model to stop generating.
   /// Our models will normally stop when they have naturally completed their turn, which will result in a response stop_reason of "end_turn".
   /// If you want the model to stop generating when it encounters custom strings of text, you can use the stop_sequences parameter. If the model encounters one of the custom sequences, the response stop_reason value will be "stop_sequence" and the response stop_sequence value will contain the matched stop sequence.
   public let stopSequences: [String]?
   
   /// Whether to incrementally stream the response using server-sent events.
   /// See [streaming](https://docs.anthropic.com/claude/reference/messages-streaming for details.
   public var stream: Bool
   
   /// Amount of randomness injected into the response.
   /// Defaults to 1. Ranges from 0 to 1. Use temp closer to 0 for analytical / multiple choice, and closer to 1 for creative and generative tasks.
   public let temperature: Double?
   
   /// Only sample from the top K options for each subsequent token.
   /// Used to remove "long tail" low probability responses. [Learn more technical details here](https://towardsdatascience.com/how-to-sample-from-language-models-682bceb97277).
   public let topK: Int?
   
   /// Use nucleus sampling.
   /// In nucleus sampling, we compute the cumulative distribution over all the options for each subsequent token in decreasing probability order and cut it off once it reaches a particular probability specified by top_p. You should either alter temperature or top_p, but not both.
   public let topP: Double?
   
   /// If you include tools in your API request, the model may return tool_use content blocks that represent the model's use of those tools. You can then run those tools using the tool input generated by the model and then optionally return results back to the model using tool_result content blocks.
   ///
   /// Each tool definition includes:
   ///
   /// **name**: Name of the tool.
   ///
   /// **description**: Optional, but strongly-recommended description of the tool.
   ///
   /// **input_schema**: JSON schema for the tool input shape that the model will produce in tool_use output content blocks.
   ///
   /// **cacheControl**: Prompt Caching
   let tools: [Tool]?
   
   ///   Forcing tool use
   ///
   ///    In some cases, you may want Claude to use a specific tool to answer the user's question, even if Claude thinks it can provide an answer without using a tool. You can do this by specifying the tool in the tool_choice field like so:
   ///
   ///    tool_choice = {"type": "tool", "name": "get_weather"}
   ///    When working with the tool_choice parameter, we have three possible options:
   ///
   ///    `auto` allows Claude to decide whether to call any provided tools or not. This is the default value.
   ///    `any` tells Claude that it must use one of the provided tools, but doesn't force a particular tool.
   ///    `tool` allows us to force Claude to always use a particular tool.
   let toolChoice: ToolChoice?
   
   /// Extended thinking mode configuration
   /// Controls whether Claude's extended thinking/reasoning mode is enabled
   /// and specifies token budget allocated for thinking before responding.
   public let thinking: Thinking?
   
   public enum System: Encodable {
      case text(String)
      case list([Cache])
      
      public func encode(to encoder: Encoder) throws {
         var container = encoder.singleValueContainer()
         switch self {
         case .text(let string):
            try container.encode(string)
         case .list(let objects):
            try container.encode(objects)
         }
      }
   }
   
   public struct Message: Encodable {
      
      public let role: String
      public let content: Content
      
      public enum Role: String {
         case user
         case assistant
      }
      
      public enum Content: Encodable {
         
         case text(String)
         case list([ContentObject])
         
         // Custom encoding to handle different cases
         public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .text(let text):
               try container.encode(text)
            case .list(let objects):
               try container.encode(objects)
            }
         }
         
         public enum ContentObject: Encodable {
            case text(String)
            case image(ImageSource)
            case document(DocumentSource)
            case toolUse(String, String, MessageResponse.Content.Input)
            case toolResult(String, String, Bool?, CacheControl?) // Added optional cache control
            case cache(Cache)
            case thinking(String, String)  // (thinking content, signature)
            case redactedThinking(String)  // data field for redacted thinking
            
            // Custom encoding to handle different cases
            public func encode(to encoder: Encoder) throws {
               var container = encoder.container(keyedBy: CodingKeys.self)
               switch self {
               case .text(let text):
                  try container.encode("text", forKey: .type)
                  try container.encode(text, forKey: .text)
               case .image(let source):
                  try container.encode("image", forKey: .type)
                  try container.encode(source, forKey: .source)
               case .document(let document):
                  try container.encode("document", forKey: .type)
                  // Encode the full document structure
                  try container.encode(document.source, forKey: .source)
                  try container.encodeIfPresent(document.title, forKey: .title)
                  try container.encodeIfPresent(document.context, forKey: .context)
                  try container.encodeIfPresent(document.citations, forKey: .citations)
               case .toolUse(let id, let name, let input):
                  try container.encode("tool_use", forKey: .type)
                  try container.encode(id, forKey: .id)
                  try container.encode(name, forKey: .name)
                  try container.encode(input, forKey: .input)
               case .toolResult(let toolUseId, let content, let isError, let cacheControl):
                  try container.encode("tool_result", forKey: .type)
                  try container.encode(toolUseId, forKey: .toolUseId)
                  try container.encode(content, forKey: .content)
                  try container.encodeIfPresent(isError, forKey: .isError)
                  try container.encodeIfPresent(cacheControl, forKey: .cacheControl) // Added cache control encoding
               case .cache(let cache):
                  try container.encode(cache.type.rawValue, forKey: .type)
                  try container.encode(cache.text, forKey: .text)
                  if let cacheControl = cache.cacheControl {
                     try container.encode(cacheControl, forKey: .cacheControl)
                  }
               case .thinking(let thinking, let signature):
                  try container.encode("thinking", forKey: .type)
                  try container.encode(thinking, forKey: .thinking)
                  try container.encode(signature, forKey: .signature)
               case .redactedThinking(let data):
                  try container.encode("redacted_thinking", forKey: .type)
                  try container.encode(data, forKey: .data)
               }
            }
            
            enum CodingKeys: String, CodingKey {
               case type
               case source
               case text
               case title
               case context
               case citations
               case id
               case name
               case input
               case toolUseId = "tool_use_id"
               case content
               case cacheControl = "cache_control"
               case isError = "is_error"
               case thinking
               case signature
               case data
            }
            
            // Keep the existing convenience method for backward compatibility
            public static func toolResult(_ toolUseId: String, _ content: String) -> ContentObject {
               return .toolResult(toolUseId, content, nil, nil)
            }
            
            // Add new convenience method with cache control
            public static func toolResult(_ toolUseId: String, _ content: String, cacheControl: CacheControl?) -> ContentObject {
               return .toolResult(toolUseId, content, nil, cacheControl)
            }
            
            // Add convenience method with isError
            public static func toolResult(_ toolUseId: String, _ content: String, isError: Bool?) -> ContentObject {
               return .toolResult(toolUseId, content, isError, nil)
            }
            
            // Add convenience method with both isError and cacheControl
            public static func toolResult(_ toolUseId: String, _ content: String, isError: Bool?, cacheControl: CacheControl?) -> ContentObject {
               return .toolResult(toolUseId, content, isError, cacheControl)
            }
         }
         
         public struct ImageSource: Encodable {
            
            public let type: String
            public let mediaType: String
            public let data: String
            
            public enum MediaType: String, Encodable {
               case jpeg = "image/jpeg"
               case png = "image/png"
               case gif = "image/gif"
               case webp = "image/webp"
            }
            
            public enum ImageSourceType: String, Encodable {
               case base64
            }
            
            public init(
               type: ImageSourceType,
               mediaType: MediaType,
               data: String)
            {
               self.type = type.rawValue
               self.mediaType = mediaType.rawValue
               self.data = data
            }
         }
         
         /// Represents a document source for PDF files to be processed by Claude.
         /// - Note: Maximum file size is 32MB and maximum page count is 100 pages.
         public struct DocumentSource: Encodable {
            /// The source information
            public let source: Source
            /// Optional title for the document
            public let title: String?
            /// Optional context for the document
            public let context: String?
            /// Optional citations configuration
            public let citations: Citations?
            
            public struct Source: Encodable {
               /// The type of document source
               public let type: String
               /// The media type of the document
               public let mediaType: String
               /// The document data
               public let data: String
               /// Optional cache control for the document source
               public let cacheControl: CacheControl? // Added optional cache control
               
               private enum CodingKeys: String, CodingKey {
                  case type
                  case mediaType = "media_type"
                  case data
                  case cacheControl = "cache_control" // Added cache control key
               }
               
               // Updated initializer to include cache control
               public init(
                  type: String,
                  mediaType: String,
                  data: String,
                  cacheControl: CacheControl? = nil
               ) {
                  self.type = type
                  self.mediaType = mediaType
                  self.data = data
                  self.cacheControl = cacheControl
               }
            }
            
            public enum DocumentError: Error {
               case exceededSizeLimit
               case invalidBase64Data
            }
            
            public enum MediaType: String, Encodable {
               case pdf = "application/pdf"
               case plainText = "text/plain"
               
               var maxSize: Int {
                  switch self {
                  case .pdf: return 32_000_000 // 32MB
                  case .plainText: return 32_000_000
                  }
               }
            }
            
            public enum DocumentSourceType: String, Encodable {
               case base64
               case text
            }
            
            public struct Citations: Encodable {
               public let enabled: Bool
               
               public init(enabled: Bool) {
                  self.enabled = enabled
               }
            }
            
            // Updated initializer to include cache control
            public init(
               type: DocumentSourceType = .base64,
               mediaType: MediaType,
               data: String,
               title: String? = nil,
               context: String? = nil,
               citations: Citations? = nil,
               cacheControl: CacheControl? = nil // Added optional cache control parameter
            ) throws {
               // For text type, no need to validate base64
               if type == .base64 {
                  // Validate base64 data
                  guard let decodedData = Data(base64Encoded: data) else {
                     throw DocumentError.invalidBase64Data
                  }
                  
                  // Validate size limit
                  guard decodedData.count <= mediaType.maxSize else {
                     throw DocumentError.exceededSizeLimit
                  }
               }
               
               self.source = Source(
                  type: type.rawValue,
                  mediaType: mediaType.rawValue,
                  data: data,
                  cacheControl: cacheControl // Added cache control
               )
               self.title = title
               self.context = context
               self.citations = citations
            }
            
            /// Creates a plain text document source
            public static func plainText(
               data: String,
               title: String? = nil,
               context: String? = nil,
               citations: Citations? = nil,
               cacheControl: CacheControl? = nil // Added optional cache control
            ) throws -> DocumentSource {
               try DocumentSource(
                  type: .text,
                  mediaType: .plainText,
                  data: data,
                  title: title,
                  context: context,
                  citations: citations,
                  cacheControl: cacheControl // Added cache control
               )
            }
            
            /// Creates a PDF document source
            public static func pdf(
               base64Data: String,
               title: String? = nil,
               context: String? = nil,
               citations: Citations? = nil,
               cacheControl: CacheControl? = nil // Added optional cache control
            ) throws -> DocumentSource {
               try DocumentSource(
                  type: .base64,
                  mediaType: .pdf,
                  data: base64Data,
                  title: title,
                  context: context,
                  citations: citations,
                  cacheControl: cacheControl // Added cache control
               )
            }
         }
      }
      
      public init(
         role: Role,
         content: Content)
      {
         self.role = role.rawValue
         self.content = content
      }
   }
   
   public struct MetaData: Encodable {
      // An external identifier for the user who is associated with the request.
      // This should be a uuid, hash value, or other opaque identifier. Anthropic may use this id to help detect abuse. Do not include any identifying information such as name, email address, or phone number.
      public let userId: UUID
   }
   
   public struct ToolChoice: Codable {
      public enum ToolType: String, Codable {
         case tool
         case auto
         case any
      }
      
      let type: ToolType
      let name: String?
      let disableParallelToolUse: Bool?
      
      public init(
         type: ToolType,
         name: String? = nil,
         disableParallelToolUse: Bool? = nil)
      {
         self.type = type
         self.name = name
         self.disableParallelToolUse = disableParallelToolUse
      }
      
      private enum CodingKeys: String, CodingKey {
         case type
         case name
         case disableParallelToolUse = "disable_parallel_tool_use"
      }
   }
   
   public enum Tool: Codable, Equatable {
      
      /// Standard function tool with schema
      ///
      /// name: The name of the function to be called. Must be a-z, A-Z, 0-9, or contain underscores and dashes, with a maximum length of 64.
      /// description: A description of what the function does, used by the model to choose when and how to call the function.
      /// inputSchema: The parameters the functions accepts, described as a JSON Schema object. See the [guide](https://docs.anthropic.com/en/docs/build-with-claude/tool-use) for examples, and the [JSON Schema reference](https://json-schema.org/understanding-json-schema) for documentation about the format.
      /// To describe a function that accepts no parameters, provide the value `{"type": "object", "properties": {}}`.
      /// cacheControl: [Prompt Caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching#caching-tool-definitions)
      case function(name: String, description: String?, inputSchema: JSONSchema?, cacheControl: CacheControl? = nil)
      
      /// Anthropic-hosted tool (like text editor)
      case hosted(type: String, name: String)
      
      /// https://docs.anthropic.com/en/docs/build-with-claude/tool-use/web-search-tool
      case webSearch(name: String = "web_search", parameters: WebSearchParameters)
      
      private enum CodingKeys: String, CodingKey {
         case name
         case description
         case inputSchema = "input_schema"
         case cacheControl = "cache_control"
         case type
         case maxUses = "max_uses"
         case allowedDomains = "allowed_domains"
         case blockedDomains = "blocked_domains"
         case userLocation = "user_location"
      }
      
      public func encode(to encoder: Encoder) throws {
         var container = encoder.container(keyedBy: CodingKeys.self)
         
         switch self {
         case .function(let name, let description, let inputSchema, let cacheControl):
            try container.encode(name, forKey: .name)
            try container.encodeIfPresent(description, forKey: .description)
            try container.encodeIfPresent(inputSchema, forKey: .inputSchema)
            try container.encodeIfPresent(cacheControl, forKey: .cacheControl)
            
         case .hosted(let type, let name):
            try container.encode(type, forKey: .type)
            try container.encode(name, forKey: .name)
            
         case .webSearch(let name, let parameters):
            try container.encode("web_search_20250305", forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encodeIfPresent(parameters.maxUses, forKey: .maxUses)
            try container.encodeIfPresent(parameters.allowedDomains, forKey: .allowedDomains)
            try container.encodeIfPresent(parameters.blockedDomains, forKey: .blockedDomains)
            try container.encodeIfPresent(parameters.userLocation, forKey: .userLocation)
         }
      }
      
      public init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)
         
         if container.contains(.type) {
            let type = try container.decode(String.self, forKey: .type)
            let name = try container.decode(String.self, forKey: .name)
            
            if type == "web_search_20250305" {
               let maxUses = try container.decodeIfPresent(Int.self, forKey: .maxUses)
               let allowedDomains = try container.decodeIfPresent([String].self, forKey: .allowedDomains)
               let blockedDomains = try container.decodeIfPresent([String].self, forKey: .blockedDomains)
               let userLocation = try container.decodeIfPresent(UserLocation.self, forKey: .userLocation)
               
               let parameters = WebSearchParameters(
                  maxUses: maxUses,
                  allowedDomains: allowedDomains,
                  blockedDomains: blockedDomains,
                  userLocation: userLocation
               )
               
               self = .webSearch(name: name, parameters: parameters)
            } else {
               self = .hosted(type: type, name: name)
            }
         } else {
            // Function tool
            let name = try container.decode(String.self, forKey: .name)
            let description = try container.decodeIfPresent(String.self, forKey: .description)
            let inputSchema = try container.decodeIfPresent(JSONSchema.self, forKey: .inputSchema)
            let cacheControl = try container.decodeIfPresent(CacheControl.self, forKey: .cacheControl)
            self = .function(name: name, description: description, inputSchema: inputSchema, cacheControl: cacheControl)
         }
      }
   }
   
   /// [Prompt Caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
   public struct Cache: Encodable {
      let type: CacheType
      let text: String
      let cacheControl: CacheControl?
      
      public init(
         type: CacheType = .text,
         text: String,
         cacheControl: CacheControl?)
      {
         self.type = type
         self.text = text
         self.cacheControl = cacheControl
      }
      
      public enum CacheType: String, Encodable {
         case text
      }
   }
   
   public struct CacheControl: Codable, Equatable {
      
      let type: CacheControlType
      
      public init(type: CacheControlType) {
         self.type = type
      }
      
      public enum CacheControlType: String, Codable {
         case ephemeral
      }
   }
   
   public struct Thinking: Encodable {
      /// The type of thinking, currently only "enabled" is supported
      let type: ThinkingType
      /// Token budget allocated for extended thinking (maximum number of tokens to use for thinking)
      let budgetTokens: Int
      
      public enum ThinkingType: String, Encodable {
         case enabled
      }
      
      private enum CodingKeys: String, CodingKey {
         case type
         case budgetTokens = "budget_tokens"
      }
      
      public init(type: ThinkingType = .enabled, budgetTokens: Int) {
         self.type = type
         self.budgetTokens = budgetTokens
      }
   }
   
   // MARK: - Web Search Types
   
   /// Parameters for web search tool
   public struct WebSearchParameters: Codable, Equatable {
      public let maxUses: Int?
      public let allowedDomains: [String]?
      public let blockedDomains: [String]?
      public let userLocation: UserLocation?
      
      public init(
         maxUses: Int? = nil,
         allowedDomains: [String]? = nil,
         blockedDomains: [String]? = nil,
         userLocation: UserLocation? = nil
      ) {
         self.maxUses = maxUses
         self.allowedDomains = allowedDomains
         self.blockedDomains = blockedDomains
         self.userLocation = userLocation
      }
   }
   
   /// User location for search localization
   public struct UserLocation: Codable, Equatable {
      public let type: LocationType
      public let city: String?
      public let region: String?
      public let country: String?
      public let timezone: String?
      
      public enum LocationType: String, Codable {
         case approximate
      }
      
      public init(
         type: LocationType = .approximate,
         city: String? = nil,
         region: String? = nil,
         country: String? = nil,
         timezone: String? = nil
      ) {
         self.type = type
         self.city = city
         self.region = region
         self.country = country
         self.timezone = timezone
      }
   }
   
   public init(
      model: Model,
      messages: [Message],
      maxTokens: Int,
      system: System? = nil,
      metadata: MetaData? = nil,
      stopSequences: [String]? = nil,
      stream: Bool = false,
      temperature: Double? = nil,
      topK: Int? = nil,
      topP: Double? = nil,
      tools: [Tool]? = nil,
      toolChoice: ToolChoice? = nil,
      thinking: Thinking? = nil)
   {
      self.model = model.value
      self.messages = messages
      self.maxTokens = maxTokens
      self.system = system
      self.metadata = metadata
      self.stopSequences = stopSequences
      self.stream = stream
      self.temperature = temperature
      self.topK = topK
      self.topP = topP
      self.tools = tools
      self.toolChoice = toolChoice
      self.thinking = thinking
   }
}
```

## Sources/Anthropic/Public/Parameters/Message/MessageTokenCountParameter.swift
```swift
//
//  MessageTokenCountParameter.swift
//  SwiftAnthropic
//
//  Created by James Rochabrun on 1/3/25.
//

import Foundation

public struct MessageTokenCountParameter: Encodable {
   
   /// The model that will complete your prompt.
   /// See [models](https://docs.anthropic.com/claude/reference/selecting-a-model) for additional details and options.
   public let model: String
   
   /// Input messages.
   /// Our models are trained to operate on alternating user and assistant conversational turns.
   /// Each input message must be an object with a role and content.
   public let messages: [MessageParameter.Message]
   
   /// System prompt.
   /// A system prompt is a way of providing context and instructions to Claude.
   /// System role can be either a simple String or an array of objects, use the objects array for prompt caching.
   public let system: MessageParameter.System?
   
   /// Tools that can be used in the messages
   public let tools: [MessageParameter.Tool]?
   
   public init(
      model: Model,
      messages: [MessageParameter.Message],
      system: MessageParameter.System? = nil,
      tools: [MessageParameter.Tool]? = nil)
   {
      self.model = model.value
      self.messages = messages
      self.system = system
      self.tools = tools
   }
}
```

## Sources/Anthropic/Public/Parameters/TextCompletion/TextCompletionParameter.swift
```swift
//
//  TextCompletionParameter.swift
//
//
//  Created by James Rochabrun on 1/28/24.
//

import Foundation

/// [Create a Text Completion](https://docs.anthropic.com/claude/reference/complete_post)
/// POST: https://api.anthropic.com/v1/complete
public struct TextCompletionParameter: Encodable {
   
   /// The model that will complete your prompt.
   /// As we improve Claude, we develop new versions of it that you can query. The model parameter controls which version of Claude responds 
   /// to your request. Right now we offer two model families: Claude, and Claude Instant. You can use them by setting model to "claude-2.1" or "claude-instant-1.2", respectively.
   /// See [models](https://docs.anthropic.com/claude/reference/selecting-a-model) for additional details and options.
   public let model: String
   
   /// The prompt that you want Claude to complete.
   ///
   /// For proper response generation you will need to format your prompt using alternating \n\nHuman: and \n\nAssistant: conversational turns. For example:
   /// ```
   /// "\n\nHuman: {userQuestion}\n\nAssistant:"`
   /// ```
   ///
   /// See [prompt validation](https://anthropic.readme.io/claude/reference/prompt-validation) and our guide to [prompt design](https://docs.anthropic.com/claude/docs/introduction-to-prompt-designhttps://docs.anthropic.com/claude/docs/introduction-to-prompt-design) for more details.
   public let prompt: String
   
   /// The maximum number of tokens to generate before stopping.
   /// Note that our models may stop before reaching this maximum. This parameter only specifies the absolute maximum number of tokens to generate.
   public let maxTokensToSample: Int
   
   /// Sequences that will cause the model to stop generating.
   /// Our models stop on `\n\nHuman:`, and may include additional built-in stop sequences in the future. By providing the stop_sequences parameter, you may include additional strings that will cause the model to stop generating.
   public let stopSequences: [String]?
   
   /// Amount of randomness injected into the response.
   ///
   /// Defaults to 1. Ranges from 0 to 1. Use temp closer to 0 for analytical / multiple choice, and closer to 1 for creative and generative tasks.
   public let temperature: Double?
   
   /// Use nucleus sampling.
   ///
   /// In nucleus sampling, we compute the cumulative distribution over all the options for each subsequent token in decreasing probability order and
   /// cut it off once it reaches a particular probability specified by top_p. You should either alter temperature or top_p, but not both.
   public let topP: Int?
   
   /// Only sample from the top K options for each subsequent token.
   ///
   /// Used to remove "long tail" low probability responses. [Learn more technical details here](https://towardsdatascience.com/how-to-sample-from-language-models-682bceb97277).
   public let topK: Int?
   
   /// An object describing metadata about the request.
   public let metadata: MetaData?
   
   /// Whether to incrementally stream the response using server-sent events.
   /// See [streaming](https://docs.anthropic.com/claude/reference/text-completions-streaming) for details.
   public var stream: Bool
   
   public struct MetaData: Encodable {
      /// An external identifier for the user who is associated with the request.
      /// This should be a uuid, hash value, or other opaque identifier. Anthropic may use this id to help detect abuse. Do not include any identifying information such as name, email address, or phone number.
      public let userId: UUID
   }
   
   public init(
      model: Model,
      prompt: String,
      maxTokensToSample: Int,
      stopSequences: [String]? = nil,
      temperature: Double? = nil,
      topP: Int? = nil,
      topK: Int? = nil,
      metadata: MetaData? = nil,
      stream: Bool = false)
   {
      self.model = model.value
      self.prompt = prompt
      self.maxTokensToSample = maxTokensToSample
      self.stopSequences = stopSequences
      self.temperature = temperature
      self.topP = topP
      self.topK = topK
      self.metadata = metadata
      self.stream = stream
   }
}
```

## Sources/Anthropic/Public/ResponseModels/ErrorResponse.swift
```swift
//
//  ErrorResponse.swift
//
//
//  Created by James Rochabrun on 1/28/24.
//

import Foundation

/*
 HTTP errors
 Our API follows a predictable HTTP error code format:

 400 - Invalid request: there was an issue with the format or content of your request.
 401 - Unauthorized: there's an issue with your API key.
 403 - Forbidden: your API key does not have permission to use the specified resource.
 404 - Not found: the requested resource was not found.
 429 - Your account has hit a rate limit.
 500 - An unexpected error has occurred internal to Anthropic's systems.
 529 - Anthropic's API is temporarily overloaded.
 When receiving a streaming response via SSE, it's possible that an error can occur after returning a 200 response, in which case error handling wouldn't follow these standard mechanisms.

 Error shapes
 Errors are always returned as JSON, with a top-level error object that always includes a type and message value. For example:

```JSON

 {
   "type": "error",
   "error": {
     "type": "not_found_error",
     "message": "The requested resource could not be found."
   }
 }
 ```
 
 In accordance with our versioning policy, we may expand the values within these objects, and it is possible that the type values will grow over time.

 Rate limits
 Our rate limits are currently measured in number of concurrent requests across your organization, and will default to 1 while you’re evaluating the API. This means that your organization can make at most 1 request at a time to our API.

 If you exceed the rate limit you will get a 429 error. Once you’re ready to go live we’ll discuss the appropriate rate limit with you.
 */

struct ErrorResponse: Decodable {
   
   let type: String
   let error: Error
   
   struct Error: Decodable {
      
      let type: String
      
      let message: String
   }
}

```

## Sources/Anthropic/Public/ResponseModels/Message/MessageInputTokens.swift
```swift
//
//  MessageInputTokens.swift
//  SwiftAnthropic
//
//  Created by James Rochabrun on 1/3/25.
//

import Foundation

public struct MessageInputTokens: Decodable {
   
   /// The total number of tokens across the provided list of messages, system prompt, and tools.
   public let inputTokens: Int
   
   public init(from decoder: Decoder) throws {
      if let container = try? decoder.singleValueContainer(),
         let dict = try? container.decode([String: Int].self),
         let tokens = dict["input_tokens"] {
         self.inputTokens = tokens
      } else {
         // Try regular JSON decoding as fallback
         let container = try decoder.container(keyedBy: CodingKeys.self)
         self.inputTokens = try container.decode(Int.self, forKey: .inputTokens)
      }
   }
   
   private enum CodingKeys: String, CodingKey {
      case inputTokens = "input_tokens"
   }
}
```

## Sources/Anthropic/Public/ResponseModels/Message/MessageResponse+DynamicContent.swift
```swift
//
//  MessageResponse+DynamicContent.swift
//  SwiftAnthropic
//
//  Created by James Rochabrun on 5/22/25.
//

import Foundation

public extension Dictionary where Key == String, Value == MessageResponse.Content.DynamicContent {
  
  /// Creates a formatted string representation of the dictionary
  /// - Parameters:
  ///   - indent: The indentation level (default: 0)
  ///   - indentSize: Number of spaces per indent level (default: 2)
  /// - Returns: A formatted string representation
  func formattedDescription(indent: Int = 0, indentSize: Int = 2) -> String {
    let indentation = String(repeating: " ", count: indent * indentSize)
    let nextIndent = indent + 1
    
    return self.map { key, value in
      let valueStr = formatValue(value, indent: nextIndent, indentSize: indentSize)
      return "\(indentation)\(key): \(valueStr)"
    }.joined(separator: "\n")
  }
  
  /// Formats a single DynamicContent value
  private func formatValue(_ value: MessageResponse.Content.DynamicContent, indent: Int, indentSize: Int) -> String {
    let indentation = String(repeating: " ", count: indent * indentSize)
    
    switch value {
    case .string(let str):
      return "\"\(str)\""
      
    case .integer(let num):
      return "\(num)"
      
    case .double(let num):
      return "\(num)"
      
    case .bool(let bool):
      return "\(bool)"
      
    case .null:
      return "null"
      
    case .dictionary(let dict):
      let dictStr = dict.formattedDescription(indent: indent + 1, indentSize: indentSize)
      return "{\n\(dictStr)\n\(indentation)}"
      
    case .array(let arr):
      if arr.isEmpty {
        return "[]"
      }
      
      let items = arr.enumerated().map { index, item in
        let itemStr = formatValue(item, indent: indent + 1, indentSize: indentSize)
        return "\(indentation)  [\(index)]: \(itemStr)"
      }.joined(separator: "\n")
      
      return "[\n\(items)\n\(indentation)]"
    }
  }
}
```

## Sources/Anthropic/Public/ResponseModels/Message/MessageResponse.swift
```swift
//
//  MessageResponse.swift
//
//
//  Created by James Rochabrun on 1/28/24.
//

import Foundation

/// [Message Response](https://docs.anthropic.com/claude/reference/messages_post)
public struct MessageResponse: Decodable {
  /// Unique object identifier.
  ///
  /// The format and length of IDs may change over time.
  public let id: String?
  
  /// e.g: "message"
  public let type: String?
  
  /// The model that handled the request.
  public let model: String?
  
  /// Conversational role of the generated message.
  ///
  /// This will always be "assistant".
  public let role: String
  
  /// Array of Content objects representing blocks of content generated by the model.
  ///
  /// Each content block has a `type` that determines its structure.
  ///
  /// - Example text:
  ///   ```
  ///   [{"type": "text", "text": "Hi, I'm Claude."}]
  ///   ```
  ///
  /// - Example thinking:
  ///   ```
  ///   [{"type": "thinking", "thinking": "To approach this, let's think about...", "signature": "zbbJhb..."}]
  ///   ```
  ///
  /// - Example tool use:
  ///   ```
  ///   [{"type": "tool_use", "id": "toolu_01A09q90qw90lq917835lq9", "name": "get_weather", "input": { "location": "San Francisco, CA", "unit": "celsius"}}]
  ///   ```
  /// This structure facilitates the integration and manipulation of model-generated content within your application.
  public let content: [Content]
  
  /// indicates why the process was halted.
  ///
  /// This property can hold one of the following values to describe the stop reason:
  /// - `"end_turn"`: The model reached a natural stopping point.
  /// - `"max_tokens"`: The requested `max_tokens` limit or the model's maximum token limit was exceeded.
  /// - `"stop_sequence"`: A custom stop sequence provided by you was generated.
  ///
  /// It's important to note that the values for `stopReason` here differ from those in `/v1/complete`, specifically in how `end_turn` and `stop_sequence` are distinguished.
  ///
  /// - In non-streaming mode, `stopReason` is always non-null, indicating the reason for stopping.
  /// - In streaming mode, `stopReason` is null in the `message_start` event and non-null in all other cases, providing context for the stoppage.
  ///
  /// This design allows for a detailed understanding of the process flow and its termination points.
  public let stopReason: String?
  
  /// Which custom stop sequence was generated.
  ///
  /// This value will be non-null if one of your custom stop sequences was generated.
  public let stopSequence: String?
  
  /// Container for the number of tokens used.
  public let usage: Usage
  
  public enum Content: Codable {
    public typealias Input = [String: DynamicContent]
    public typealias Citations = [Citation]
    
    public struct ToolUse: Codable {
      public let id: String
      public let name: String
      public let input: Input
    }
    
    public struct Thinking: Codable {
      public let thinking: String
      public let signature: String?
    }
    
    public struct ServerToolUse: Codable {
      public let id: String
      public let input: Input
      public let type: String
      public let name: String
    }
    
    public struct ToolResult: Codable {
      public let content: ToolResultContent
      public let isError: Bool?
      public let toolUseId: String?
    }
    
    public struct WebSearchToolResult: Codable {
      public let toolUseId: String?
      public let content: [ContentItem]
      public let type: String
      
      private enum CodingKeys: String, CodingKey {
        case toolUseId = "tool_use_id"
        case content
        case type
      }
    }
    
    case text(String, Citations?)
    case toolUse(ToolUse)
    case thinking(Thinking)
    case serverToolUse(ServerToolUse)
    case webSearchToolResult(WebSearchToolResult)
    case toolResult(ToolResult)
    
    private enum CodingKeys: String, CodingKey {
      case type, text, id, name, input, citations, thinking, signature
      case toolUseId = "tool_use_id"
      case content
      case isError
    }
    
    public enum DynamicContent: Codable {
      case string(String)
      case integer(Int)
      case double(Double)
      case dictionary(Input)
      case array([DynamicContent])
      case bool(Bool)
      case null
      
      public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
          self = .integer(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
          self = .double(doubleValue)
        } else if let stringValue = try? container.decode(String.self) {
          self = .string(stringValue)
        } else if let boolValue = try? container.decode(Bool.self) {
          self = .bool(boolValue)
        } else if container.decodeNil() {
          self = .null
        } else if let arrayValue = try? container.decode([DynamicContent].self) {
          self = .array(arrayValue)
        } else if let dictionaryValue = try? container.decode([String: DynamicContent].self) {
          self = .dictionary(dictionaryValue)
        } else {
          throw DecodingError.dataCorruptedError(in: container, debugDescription: "Content cannot be decoded")
        }
      }
      
      public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let val):
          try container.encode(val)
        case .integer(let val):
          try container.encode(val)
        case .double(let val):
          try container.encode(val)
        case .dictionary(let val):
          try container.encode(val)
        case .array(let val):
          try container.encode(val)
        case .bool(let val):
          try container.encode(val)
        case .null:
          try container.encodeNil()
        }
      }
    }
    
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let type = try container.decode(String.self, forKey: .type)
      switch type {
      case "text":
        let text = try container.decode(String.self, forKey: .text)
        let citations = try container.decodeIfPresent(Citations.self, forKey: .citations)
        self = .text(text, citations)
      case "tool_use":
        let id = try container.decode(String.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let input = try container.decode(Input.self, forKey: .input)
        self = .toolUse(ToolUse(id: id, name: name, input: input))
      case "thinking":
        let thinking = try container.decode(String.self, forKey: .thinking)
        let signature = try container.decodeIfPresent(String.self, forKey: .signature)
        self = .thinking(Thinking(thinking: thinking, signature: signature))
      case "server_tool_use":
        let id = try container.decode(String.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let input = try container.decode(Input.self, forKey: .input)
        let type = try container.decode(String.self, forKey: .type)
        self = .serverToolUse(ServerToolUse(id: id, input: input, type: type, name: name))
      case "web_search_tool_result":
        let toolUseId = try container.decodeIfPresent(String.self, forKey: .toolUseId)
        let content = try container.decode([ContentItem].self, forKey: .content)
        let type = try container.decode(String.self, forKey: .type)
        self = .webSearchToolResult(WebSearchToolResult(toolUseId: toolUseId, content: content, type: type))
      case "tool_result":
        let toolUseId = try container.decodeIfPresent(String.self, forKey: .toolUseId)
        let isError = try container.decodeIfPresent(Bool.self, forKey: .isError) ?? false

        // Now decode the flexible content type
        let content = try container.decode(ToolResultContent.self, forKey: .content)
        self = .toolResult(ToolResult(content: content, isError: isError, toolUseId: toolUseId))
      default:
        throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type value found in JSON!")
      }
    }
    
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      switch self {
      case .text(let text, let citations):
        try container.encode("text", forKey: .type)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(citations, forKey: .citations)
      case .toolUse(let toolUse):
        try container.encode("tool_use", forKey: .type)
        try container.encode(toolUse.id, forKey: .id)
        try container.encode(toolUse.name, forKey: .name)
        try container.encode(toolUse.input, forKey: .input)
      case .thinking(let thinking):
        try container.encode("thinking", forKey: .type)
        try container.encode(thinking.thinking, forKey: .thinking)
        try container.encodeIfPresent(thinking.signature, forKey: .signature)
      case .serverToolUse(let serverToolUse):
        try container.encode("server_tool_use", forKey: .type)
        try container.encode(serverToolUse.id, forKey: .id)
        try container.encode(serverToolUse.name, forKey: .name)
        try container.encode(serverToolUse.input, forKey: .input)
      case .webSearchToolResult(let webSearchResult):
        try container.encode("web_search_tool_result", forKey: .type)
        try container.encode(webSearchResult.toolUseId, forKey: .toolUseId)
        try container.encode(webSearchResult.content, forKey: .content)
      case .toolResult(let toolResult):
        try container.encode("tool_result", forKey: .type)
        try container.encode(toolResult.content, forKey: .content)
        try container.encodeIfPresent(toolResult.isError, forKey: .isError)
        try container.encodeIfPresent(toolResult.toolUseId, forKey: .toolUseId)
      }
    }
  }
  
  /// Claude is capable of providing detailed citations when answering questions about documents, helping you track and verify information sources in responses.
  /// https://docs.anthropic.com/en/docs/build-with-claude/citations
  public enum Citation: Codable {
    case charLocation(CharLocation)
    case pageLocation(PageLocation)
    case contentBlockLocation(ContentBlockLocation)
    case webSearchResultLocation(WebSearchResultLocation)
    
    private enum CodingKeys: String, CodingKey {
      case type
      case citedText
      case documentIndex
      case documentTitle
      case startCharIndex
      case endCharIndex
      case startPageNumber
      case endPageNumber
      case startBlockIndex
      case endBlockIndex
      case url
      case title
      case encryptedIndex
    }
    
    public struct CharLocation: Codable {
      public let citedText: String?
      public let documentIndex: Int?
      public let documentTitle: String?
      public let startCharIndex: Int?
      public let endCharIndex: Int?
    }
    
    public struct PageLocation: Codable {
      public let citedText: String?
      public let documentIndex: Int?
      public let documentTitle: String?
      public let startPageNumber: Int?
      public let endPageNumber: Int?
    }
    
    public struct ContentBlockLocation: Codable {
      public let citedText: String?
      public let documentIndex: Int?
      public let documentTitle: String?
      public let startBlockIndex: Int?
      public let endBlockIndex: Int?
    }
    
    public struct WebSearchResultLocation: Codable {
      public let url: String?
      public let title: String?
      public let encryptedIndex: String?
      public let citedText: String?
    }
    
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let type = try container.decode(String.self, forKey: .type)
      
      switch type {
      case "char_location":
        self = .charLocation(CharLocation(
          citedText: try container.decodeIfPresent(String.self, forKey: .citedText),
          documentIndex: try container.decodeIfPresent(Int.self, forKey: .documentIndex),
          documentTitle: try container.decodeIfPresent(String.self, forKey: .documentTitle),
          startCharIndex: try container.decodeIfPresent(Int.self, forKey: .startCharIndex),
          endCharIndex: try container.decodeIfPresent(Int.self, forKey: .endCharIndex)
        ))
      case "page_location":
        self = .pageLocation(PageLocation(
          citedText: try container.decodeIfPresent(String.self, forKey: .citedText),
          documentIndex: try container.decodeIfPresent(Int.self, forKey: .documentIndex),
          documentTitle: try container.decodeIfPresent(String.self, forKey: .documentTitle),
          startPageNumber: try container.decodeIfPresent(Int.self, forKey: .startPageNumber),
          endPageNumber: try container.decodeIfPresent(Int.self, forKey: .endPageNumber)
        ))
      case "content_block_location":
        self = .contentBlockLocation(ContentBlockLocation(
          citedText: try container.decodeIfPresent(String.self, forKey: .citedText),
          documentIndex: try container.decodeIfPresent(Int.self, forKey: .documentIndex),
          documentTitle: try container.decodeIfPresent(String.self, forKey: .documentTitle),
          startBlockIndex: try container.decodeIfPresent(Int.self, forKey: .startBlockIndex),
          endBlockIndex: try container.decodeIfPresent(Int.self, forKey: .endBlockIndex)
        ))
      case "web_search_result_location":
        self = .webSearchResultLocation(WebSearchResultLocation(
          url: try container.decodeIfPresent(String.self, forKey: .url),
          title: try container.decodeIfPresent(String.self, forKey: .title),
          encryptedIndex: try container.decodeIfPresent(String.self, forKey: .encryptedIndex),
          citedText: try container.decodeIfPresent(String.self, forKey: .citedText)
        ))
      default:
        throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid citation type!")
      }
    }
    
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      
      switch self {
      case .charLocation(let location):
        try container.encode("char_location", forKey: .type)
        try container.encodeIfPresent(location.citedText, forKey: .citedText)
        try container.encodeIfPresent(location.documentIndex, forKey: .documentIndex)
        try container.encodeIfPresent(location.documentTitle, forKey: .documentTitle)
        try container.encodeIfPresent(location.startCharIndex, forKey: .startCharIndex)
        try container.encodeIfPresent(location.endCharIndex, forKey: .endCharIndex)
      case .pageLocation(let location):
        try container.encode("page_location", forKey: .type)
        try container.encodeIfPresent(location.citedText, forKey: .citedText)
        try container.encodeIfPresent(location.documentIndex, forKey: .documentIndex)
        try container.encodeIfPresent(location.documentTitle, forKey: .documentTitle)
        try container.encodeIfPresent(location.startPageNumber, forKey: .startPageNumber)
        try container.encodeIfPresent(location.endPageNumber, forKey: .endPageNumber)
      case .contentBlockLocation(let location):
        try container.encode("content_block_location", forKey: .type)
        try container.encodeIfPresent(location.citedText, forKey: .citedText)
        try container.encodeIfPresent(location.documentIndex, forKey: .documentIndex)
        try container.encodeIfPresent(location.documentTitle, forKey: .documentTitle)
        try container.encodeIfPresent(location.startBlockIndex, forKey: .startBlockIndex)
        try container.encodeIfPresent(location.endBlockIndex, forKey: .endBlockIndex)
      case .webSearchResultLocation(let location):
        try container.encode("web_search_result_location", forKey: .type)
        try container.encodeIfPresent(location.url, forKey: .url)
        try container.encodeIfPresent(location.title, forKey: .title)
        try container.encodeIfPresent(location.encryptedIndex, forKey: .encryptedIndex)
        try container.encodeIfPresent(location.citedText, forKey: .citedText)
      }
    }
  }
  
  public struct Usage: Codable {
    /// The number of input tokens which were used.
    public let inputTokens: Int?
    
    /// The number of output tokens which were used.
    public let outputTokens: Int
    
    /// The number of thinking tokens which were used (when thinking mode is enabled).
    public let thinkingTokens: Int?
    
    /// [Prompt Caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching#how-can-i-track-the-effectiveness-of-my-caching-strategy)
    /// You can monitor cache performance using the cache_creation_input_tokens and cache_read_input_tokens fields in the API response.
    public let cacheCreationInputTokens: Int?
    
    /// [Prompt Caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching#how-can-i-track-the-effectiveness-of-my-caching-strategy)
    /// You can monitor cache performance using the cache_creation_input_tokens and cache_read_input_tokens fields in the API response.
    public let cacheReadInputTokens: Int?
    
    /// Server tool usage information - NEW
    public let serverToolUse: ServerToolUse?
  }
  
  public struct ServerToolUse: Codable {
    /// Number of web search requests performed
    public let webSearchRequests: Int?
  }
}

/// Extension to provide convenient access to thinking content
extension MessageResponse {
  
  /// Extracts all thinking content blocks from the response
  /// - Returns: Array of thinking content or empty array if none found
  public func getThinkingContent() -> [Content.Thinking] {
    return content.compactMap { contentBlock in
      if case .thinking(let thinking) = contentBlock {
        return thinking
      }
      return nil
    }
  }
  
  /// Get the first thinking content block from the response
  /// - Returns: The first thinking content block or nil if none exists
  public func getFirstThinkingContent() -> Content.Thinking? {
    return getThinkingContent().first
  }
  
  /// Get the combined thinking content as a single string
  /// - Returns: All thinking content concatenated into a single string, or nil if no thinking content exists
  public func getCombinedThinkingContent() -> String? {
    let thinkingBlocks = getThinkingContent()
    if thinkingBlocks.isEmpty {
      return nil
    }
    
    return thinkingBlocks.map { $0.thinking }.joined(separator: "\n\n")
  }
  
  /// Determines if the response contains any thinking content
  /// - Returns: True if thinking content exists, false otherwise
  public var hasThinkingContent: Bool {
    return content.contains { contentBlock in
      if case .thinking = contentBlock {
        return true
      }
      return false
    }
  }
}

// MARK: MessageResponse.Content + DynamicContent

public extension MessageResponse.Content.DynamicContent {
  var stringValue: String? {
    if case .string(let value) = self {
      return value
    }
    return nil
  }
  
  var intValue: Int? {
    if case .integer(let value) = self {
      return value
    }
    return nil
  }
  
  var boolValue: Bool? {
    if case .bool(let value) = self {
      return value
    }
    return nil
  }
  
  var arrayValue: [MessageResponse.Content.DynamicContent]? {
    if case .array(let value) = self {
      return value
    }
    return nil
  }
  
  var dictionaryValue: [String: MessageResponse.Content.DynamicContent]? {
    if case .dictionary(let value) = self {
      return value
    }
    return nil
  }
}

// MARK: MessageResponse.Content + TextEditorCommand

public extension MessageResponse.Content {
  
  enum TextEditorCommand: String {
    case view
    case str_replace
    case insert
    case create
    case undo_edit
    
    // Helper to extract command from input
    public static func from(_ input: [String: DynamicContent]) -> TextEditorCommand? {
      guard let commandValue = input["command"]?.stringValue else { return nil }
      return TextEditorCommand(rawValue: commandValue)
    }
  }
}

// MARK: MessageResponse.Content + ToolResultContent

public extension MessageResponse.Content {
  
  public enum ToolResultContent: Codable {
    case string(String)
    case items([ContentItem])
    
    public init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      
      if let stringValue = try? container.decode(String.self) {
        self = .string(stringValue)
      } else if let itemsArray = try? container.decode([ContentItem].self) {
        self = .items(itemsArray)
      } else {
        throw DecodingError.dataCorruptedError(
          in: container,
          debugDescription: "ToolResultContent must be either String or [ContentItem]"
        )
      }
    }
    
    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      
      switch self {
      case .string(let value):
        try container.encode(value)
      case .items(let items):
        try container.encode(items)
      }
    }
  }
}

// MARK: ContentItem

public struct ContentItem: Codable {
  public let encryptedContent: String?
  public let title: String?
  public let pageAge: String?
  public let type: String?
  public let url: String?
  public let text: String?
  
  var description: String {
    var result = "ContentItem:\n"
    
    if let title = self.title {
      result += "  Title: \"\(title)\"\n"
    }
    
    if let url = self.url {
      result += "  URL: \(url)\n"
    }
    
    if let type = self.type {
      result += "  Type: \(type)\n"
    }
    
    if let pageAge = self.pageAge {
      result += "  Age: \(pageAge)\n"
    }
    
    if let text = self.text {
      // Limit text length for readability
      let truncatedText = text.count > 100 ? "\(text.prefix(100))..." : text
      result += "  Text: \"\(truncatedText)\"\n"
    }
    
    if let encryptedContent = self.encryptedContent {
      // Just indicate presence rather than showing the whole encrypted content
      result += "  Encrypted Content: [Present]\n"
    }
    
    return result
  }
  
  private enum CodingKeys: String, CodingKey {
    case encryptedContent = "encrypted_content"
    case title
    case text
    case pageAge = "page_age"
    case type
    case url
  }
}
```

## Sources/Anthropic/Public/ResponseModels/Message/MessageStreamResponse.swift
```swift
//
//  MessageStreamResponse.swift
//
//
//  Created by James Rochabrun on 1/28/24.
//

import Foundation

/// [Message Stream Response](https://docs.anthropic.com/claude/reference/messages-streaming).
///
/// Each server-sent event includes a named event type and associated JSON data. Each event will use an SSE event name (e.g. event: message_stop), and include the matching event type in its data.
///
/// Each stream uses the following event flow:
///
/// message_start: contains a Message object with empty content.
/// A series of content blocks, each of which have a content_block_start, one or more content_block_delta events, and a content_block_stop event. Each content block will have an index that corresponds to its index in the final Message content array.
/// One or more message_delta events, indicating top-level changes to the final Message object.
/// A final message_stop event.
///
/// This structured sequence facilitates the orderly reception and processing of message components and overall changes.
public struct MessageStreamResponse: Decodable {
   
   public let type: String
   
   public let index: Int?
   
   /// available in "content_block_start" event
   public let contentBlock: ContentBlock?
   
   /// available in "message_start" event
   public let message: MessageResponse?
   
   /// Available in "content_block_delta", "message_delta" events.
   public let delta: Delta?
   
   /// Available in "message_delta" events.
   public let usage: MessageResponse.Usage?
   
   public var streamEvent: StreamEvent? {
      StreamEvent(rawValue: type)
   }
   
   public let error: Error?
   
   /// Web search tool result
   public let toolUseId: String?
   
   public let content: [WebSearchResult]?
   
   public struct Delta: Decodable {
      public let type: String?
      
      /// type = text
      public let text: String?
      
      /// type = thinking_delta
      public let thinking: String?
      
      /// type = signature_delta
      public let signature: String?
      
      /// type = tool_use
      public let partialJson: String?
      
      // type = citations_delta
      public let citation: MessageResponse.Citation?
      
      public let stopReason: String?
      
      public let stopSequence: String?
   }
   
   public struct ContentBlock: Decodable {
      
      // Can be of type `text`, `tool_use`, `thinking`, or `redacted_thinking`
      public let type: String
      
      /// `text` type
      public let text: String?
      
      /// `thinking` type
      public let thinking: String?
      
      /// `redacted_thinking` type
      public let data: String?
      
      // Citations for text type
      public let citations: [MessageResponse.Citation]?
      
      /// `tool_use` and `server_tool_use` type
      public let input: [String: MessageResponse.Content.DynamicContent]?
      
      public let name: String?
      
      public let id: String?
      
      public var toolUse: MessageResponse.Content.ToolUse? {
         guard let name, let id else { return nil }
         return .init(id: id, name: name, input: input ?? [:])
      }
   }
   
   public struct Error: Decodable {
      
      /// The error type, for example "overloaded_error"
      public let type: String
      
      /// The error message, for example "Overloaded"
      public let message: String
   }
   
   /// https://docs.anthropic.com/en/api/messages-streaming#event-types
   public enum StreamEvent: String {
      
      case contentBlockStart = "content_block_start"
      case contentBlockDelta = "content_block_delta"
      case contentBlockStop = "content_block_stop"
      case messageStart = "message_start"
      case messageDelta = "message_delta"
      case messageStop = "message_stop"
   }
}

// MARK: - Web Search Results

public struct WebSearchResult: Decodable {
   public let type: String?
   public let url: String?
   public let title: String?
   public let encryptedContent: String?
   public let pageAge: String?
   public let errorCode: String?
}

extension MessageStreamResponse {
   
   /// Helper to check if the delta contains thinking content
   public var isThinkingDelta: Bool {
      return delta?.type == "thinking_delta"
   }
   
   /// Helper to check if the delta contains a signature update
   public var isSignatureDelta: Bool {
      return delta?.type == "signature_delta"
   }
   
   /// Helper to check if the content block is a thinking block
   public var isThinkingBlock: Bool {
      return contentBlock?.type == "thinking"
   }
   
   /// Helper to check if the content block is a redacted thinking block
   public var isRedactedThinkingBlock: Bool {
      return contentBlock?.type == "redacted_thinking"
   }
   
   /// Helper to check if this is a server tool use (web search)
   public var isServerToolUse: Bool {
      return contentBlock?.type == "server_tool_use"
   }
   
   /// Helper to check if this is a web search tool result
   public var isWebSearchToolResult: Bool {
      return type == "web_search_tool_result"
   }
}
```

## Sources/Anthropic/Public/ResponseModels/TextCompletion/TextCompletionResponse.swift
```swift
//
//  TextCompletionResponse.swift
//
//
//  Created by James Rochabrun on 1/28/24.
//

import Foundation

/// [Completion Response](https://docs.anthropic.com/claude/reference/complete_post)
public struct TextCompletionResponse: Decodable {
   
   /// Unique object identifier.
   ///
   /// The format and length of IDs may change over time.
   public let id: String
   
   public let type: String
   
   /// The resulting completion up to and excluding the stop sequences.
   public let completion: String
   
   /// The reason that we stopped.
   ///
   /// This may be one the following values:
   ///
   /// - "stop_sequence": we reached a stop sequence — either provided by you via the stop_sequences parameter,
   /// or a stop sequence built into the model
   ///
   /// - "max_tokens": we exceeded max_tokens_to_sample or the model's maximum
   public let stopReason: String
   
   /// The model that handled the request.
   public let model: String
}
```

## Sources/Anthropic/Public/ResponseModels/TextCompletion/TextCompletionStreamResponse.swift
```swift
//
//  TextCompletionStreamResponse.swift
//
//
//  Created by James Rochabrun on 1/28/24.
//

import Foundation

/// [Text Completion Response](https://docs.anthropic.com/claude/reference/streaming)
public struct TextCompletionStreamResponse: Decodable {
   
   public let type: String

   public let completion: String?
   
   public let stopReason: String?
   
   public let model: String?

}
```

## Sources/Anthropic/Public/StreamHandler.swift
```swift
//
//  StreamHandler.swift
//  SwiftAnthropic
//
//  Created by James Rochabrun on 2/24/25.
//

import Foundation

public final class StreamHandler {
   
   public init() {}
   
   // Process a stream event
   public func handleStreamEvent(_ event: MessageStreamResponse) {
      // First identify event type
      switch event.streamEvent {
      case .contentBlockStart:
         handleContentBlockStart(event)
      case .contentBlockDelta:
         handleContentBlockDelta(event)
      case .contentBlockStop:
         handleContentBlockStop()
      case .messageStart:
         // Just initialize as needed
         debugPrint("Stream started")
      case .messageDelta, .messageStop:
         // Handle message completion
         if event.streamEvent == .messageStop {
            debugPrint("\nStream complete!")
            printSummary()
         }
      case .none:
         debugPrint("Unknown event type: \(event.type)")
      }
   }
   
   // Get all content blocks for use in subsequent API calls
   public func getContentBlocksForAPI() -> [MessageParameter.Message.Content.ContentObject] {
      var blocks: [MessageParameter.Message.Content.ContentObject] = []
      
      // Add regular thinking blocks
      for block in thinkingBlocks {
         if let signature = block.signature {
            blocks.append(.thinking(block.thinking, signature))
         }
      }
      
      // Add redacted thinking blocks if any
      for data in redactedThinkingBlocks {
         blocks.append(.redactedThinking(data))
      }
      
      // Add tool use blocks if any
      for toolUse in toolUseBlocks {
         blocks.append(.toolUse(toolUse.id, toolUse.name, toolUse.input))
      }
      
      return blocks
   }
   
   // Get only thinking blocks for use in subsequent API calls
   public func getThinkingBlocksForAPI() -> [MessageParameter.Message.Content.ContentObject] {
      var blocks: [MessageParameter.Message.Content.ContentObject] = []
      
      // Add regular thinking blocks
      for block in thinkingBlocks {
         if let signature = block.signature {
            blocks.append(.thinking(block.thinking, signature))
         }
      }
      
      // Add redacted thinking blocks if any
      for data in redactedThinkingBlocks {
         blocks.append(.redactedThinking(data))
      }
      
      return blocks
   }
   
   // Get text response content
   public var textResponse: String {
      return currentResponse
   }
   
   // Get tool use blocks
   public func getToolUseBlocks() -> [ToolUseBlock] {
      return toolUseBlocks
   }
   
   // Get accumulated JSON for a specific tool use ID
   public func getAccumulatedJson(forToolUseId id: String) -> String? {
      return toolUseJsonMap[id]
   }
   
   // Current thinking content being collected
   private var currentThinking = ""
   // Current signature being collected
   private var signature: String?
   // Current text response being collected
   private var currentResponse = ""
   // Current tool use block being collected
   private var currentToolUse: ToolUseBlock?
   // Accumulated JSON for the current tool use
   private var currentToolUseJson = ""
   
   // Track the current active content block index and type
   private var currentBlockIndex: Int? = nil
   private var currentBlockType: String? = nil
   
   // Store all collected thinking blocks
   private var thinkingBlocks: [(thinking: String, signature: String?)] = []
   // Stored redacted thinking blocks
   private var redactedThinkingBlocks: [String] = []
   // Stored tool use blocks
   private var toolUseBlocks: [ToolUseBlock] = []
   // Map of tool use IDs to their accumulated JSON
   private var toolUseJsonMap: [String: String] = [:]
   
   // Structure to store tool use information
   public struct ToolUseBlock {
      public let id: String
      public let name: String
      public let input: MessageResponse.Content.Input
      
      // Added for convenience
      public var accumulatedJson: String?
      
      public init(id: String, name: String, input: MessageResponse.Content.Input, accumulatedJson: String? = nil) {
         self.id = id
         self.name = name
         self.input = input
         self.accumulatedJson = accumulatedJson
      }
   }
   
   private func handleContentBlockStart(_ event: MessageStreamResponse) {
      guard let contentBlock = event.contentBlock, let index = event.index else { return }
      
      currentBlockIndex = index
      currentBlockType = contentBlock.type
      
      switch contentBlock.type {
      case "thinking":
         currentThinking = contentBlock.thinking ?? ""
         debugPrint("\nStarting thinking block...")
      case "redacted_thinking":
         if let data = contentBlock.data {
            redactedThinkingBlocks.append(data)
            debugPrint("\nEncountered redacted thinking block")
         }
      case "text":
         currentResponse = contentBlock.text ?? ""
         debugPrint("\nStarting text response...")
      case "tool_use":
         if let id = contentBlock.id, let name = contentBlock.name {
            // Initialize the JSON accumulator for this tool use
            currentToolUseJson = ""
            // Create the tool use block with initial input (may be empty)
            currentToolUse = ToolUseBlock(id: id, name: name, input: contentBlock.input ?? [:])
            debugPrint("\nStarting tool use block: \(name) with ID: \(id)")
         }
      default:
         debugPrint("\nStarting \(contentBlock.type) block...")
      }
   }
   
   private func handleContentBlockDelta(_ event: MessageStreamResponse) {
      guard let delta = event.delta, let index = event.index else { return }
      
      // Ensure we're tracking the correct block
      if currentBlockIndex != index {
         currentBlockIndex = index
      }
      
      // Process based on delta type
      switch delta.type {
      case "thinking_delta":
         if let thinking = delta.thinking {
            currentThinking += thinking
            debugPrint(thinking, terminator: "")
         }
      case "signature_delta":
         if let sig = delta.signature {
            signature = sig
            debugPrint("\nReceived signature for thinking block")
         }
      case "text_delta":
         if let text = delta.text {
            currentResponse += text
            debugPrint(text, terminator: "")
         }
      case "tool_use_delta":
         if let partialJson = delta.partialJson, let currentId = currentToolUse?.id {
            // Accumulate the JSON
            currentToolUseJson += partialJson
            // Update the map
            toolUseJsonMap[currentId] = currentToolUseJson
            debugPrint("\nAccumulated tool use JSON for \(currentId): \(partialJson)")
            
            // Try to parse the accumulated JSON if it might be complete
            if isValidJson(currentToolUseJson) {
               debugPrint("\nValid JSON detected for tool use \(currentId)")
               // Here you could attempt to update the tool use input if needed
               updateToolUseInputIfPossible(toolUseId: currentId, json: currentToolUseJson)
            }
         }
      default:
         if let type = delta.type {
            debugPrint("\nUnknown delta type: \(type)")
         }
      }
   }
   
   private func handleContentBlockStop() {
      // When a block is complete, store it if needed
      if currentBlockType == "thinking" && !currentThinking.isEmpty {
         thinkingBlocks.append((thinking: currentThinking, signature: signature))
         
         // Reset for next block
         currentThinking = ""
         signature = nil
      } else if currentBlockType == "tool_use" && currentToolUse != nil {
         if let toolUse = currentToolUse, let id = currentToolUse?.id {
            // Create a new ToolUseBlock with the accumulated JSON
            let updatedToolUse = ToolUseBlock(
               id: toolUse.id,
               name: toolUse.name,
               input: toolUse.input,
               accumulatedJson: toolUseJsonMap[id]
            )
            
            toolUseBlocks.append(updatedToolUse)
            debugPrint("\nStored tool use block with ID: \(id) and accumulated JSON")
         }
         currentToolUse = nil
         currentToolUseJson = ""
      }
      
      // Reset tracking
      currentBlockType = nil
   }
   
   // Check if a string is valid JSON
   private func isValidJson(_ jsonString: String) -> Bool {
      guard !jsonString.isEmpty else { return false }
      return (try? JSONSerialization.jsonObject(with: Data(jsonString.utf8))) != nil
   }
   
   // Try to update the tool use input from accumulated JSON
   private func updateToolUseInputIfPossible(toolUseId: String, json: String) {
      // This would be implemented based on your specific needs
      // For example, you might decode the JSON and update the corresponding input
      // This is just a placeholder for where you would implement that logic
      debugPrint("\nWould update tool use input for \(toolUseId) based on JSON if implemented")
   }
   
   // Reset all stored data
   public func reset() {
      currentThinking = ""
      signature = nil
      currentResponse = ""
      currentToolUse = nil
      currentToolUseJson = ""
      currentBlockIndex = nil
      currentBlockType = nil
      thinkingBlocks.removeAll()
      redactedThinkingBlocks.removeAll()
      toolUseBlocks.removeAll()
      toolUseJsonMap.removeAll()
   }
   
   // Print a summary of what was collected
   private func printSummary() {
      debugPrint("\n\n===== SUMMARY =====")
      debugPrint("Number of thinking blocks: \(thinkingBlocks.count)")
      debugPrint("Number of redacted thinking blocks: \(redactedThinkingBlocks.count)")
      debugPrint("Number of tool use blocks: \(toolUseBlocks.count)")
      debugPrint("Number of tool use JSON objects: \(toolUseJsonMap.count)")
      debugPrint("Final response length: \(currentResponse.count) characters")
   }
}
```

## Sources/Anthropic/Service/AnthropicService.swift
```swift
//
//  AnthropicService.swift
//
//
//  Created by James Rochabrun on 1/28/24.
//

import Foundation
#if os(Linux)
import FoundationNetworking
#endif

// MARK: Error

public enum APIError: Error {
  
  case requestFailed(description: String)
  case responseUnsuccessful(description: String)
  case invalidData
  case jsonDecodingFailure(description: String)
  case dataCouldNotBeReadMissingData(description: String)
  case bothDecodingStrategiesFailed
  case timeOutError
  
  public var displayDescription: String {
    switch self {
    case .requestFailed(let description): return description
    case .responseUnsuccessful(let description): return description
    case .invalidData: return "Invalid data"
    case .jsonDecodingFailure(let description): return description
    case .dataCouldNotBeReadMissingData(let description): return description
    case .bothDecodingStrategiesFailed: return "Decoding strategies failed."
    case .timeOutError: return "Time Out Error."
    }
  }
}

// MARK: Service

/// A protocol defining the required services for interacting with Anthropic's API.
///
/// The protocol outlines methods for fetching data and streaming responses,
/// as well as handling JSON decoding and networking tasks.
public protocol AnthropicService {
  
  /// The HTTP client responsible for executing all network requests.
  ///
  /// This client is used for tasks like sending and receiving data.
  var httpClient: HTTPClient { get }
  /// The `JSONDecoder` instance used for decoding JSON responses.
  ///
  /// This decoder is used to parse the JSON responses returned by the API
  /// into model objects that conform to the `Decodable` protocol.
  var decoder: JSONDecoder { get }
  
  // MARK: Message
  
  /// Creates a message with the provided parameters.
  ///
  /// - Parameters:
  ///   - parameters: Parameters for the create message request.
  ///
  /// - Returns: A [MessageResponse](https://docs.anthropic.com/claude/reference/messages_post).
  ///
  /// - Throws: An error if the request fails.
  ///
  /// For more information, refer to [Anthropic's Message API documentation](https://docs.anthropic.com/claude/reference/messages_post).
  func createMessage(
    _ parameter: MessageParameter)
  async throws -> MessageResponse
  
  /// Creates a message stream with the provided parameters.
  ///
  /// - Parameters:
  ///   - parameters: Parameters for the create message request.
  ///
  /// - Returns: A streamed sequence of `MessageStreamResponse`.
  ///   For more details, see [MessageStreamResponse](https://docs.anthropic.com/claude/reference/messages-streaming).
  ///
  /// - Throws: An error if the request fails.
  ///
  /// For more information, refer to [Anthropic's Stream Message API documentation](https://docs.anthropic.com/claude/reference/messages-streaming).
  func streamMessage(
    _ parameter: MessageParameter)
  async throws -> AsyncThrowingStream<MessageStreamResponse, Error>
  
  /// Counts the number of tokens that would be used by a message for a given model.
  ///
  /// - Parameters:
  ///   - parameter: The parameters used to count tokens, including the model, messages, system prompt, and tools.
  ///
  /// - Returns: A `MessageInputTokens` object containing the count of input tokens.
  ///
  /// - Throws: An error if the token counting request fails.
  ///
  /// Example usage:
  /// ```swift
  /// let parameter = MessageTokenCountParameter(
  ///     model: .claude3Sonnet,
  ///     messages: [
  ///         .init(
  ///             role: .user,
  ///             content: .text("Hello, Claude!")
  ///         )
  ///     ]
  /// )
  ///
  /// let tokenCount = try await client.countTokens(parameter: parameter)
  /// print("Input tokens: \(tokenCount.inputTokens)")
  /// ```
  ///
  /// For more details, see [Count Message tokens](https://docs.anthropic.com/en/api/messages-count-tokens)
  func countTokens(
    parameter: MessageTokenCountParameter)
  async throws -> MessageInputTokens
  
  
  // MARK: Text Completion
  
  /// - Parameter parameters: Parameters for the create text completion request.
  /// - Returns: A [TextCompletionResponse](https://docs.anthropic.com/claude/reference/complete_post).
  /// - Throws: An error if the request fails.
  ///
  /// For more information, refer to [Anthropic's Text Completion API documentation](https://docs.anthropic.com/claude/reference/complete_post).
  func createTextCompletion(
    _ parameter: TextCompletionParameter)
  async throws -> TextCompletionResponse
  
  /// - Parameter parameters: Parameters for the create stream text completion request.
  /// - Returns: A [TextCompletionResponse](https://docs.anthropic.com/claude/reference/streaming).
  /// - Throws: An error if the request fails.
  ///
  /// For more information, refer to [Anthropic's Text Completion API documentation](https://docs.anthropic.com/claude/reference/streaming).
  func createStreamTextCompletion(
    _ parameter: TextCompletionParameter)
  async throws -> AsyncThrowingStream<TextCompletionStreamResponse, Error>
}

extension AnthropicService {
  
  /// Asynchronously fetches a decodable data type from Anthropic's API.
  ///
  /// - Parameters:
  ///   - type: The `Decodable` type that the response should be decoded to.
  ///   - request: The `URLRequest` describing the API request.
  ///   - debugEnabled: If true the service will print events on DEBUG builds.
  /// - Throws: An error if the request fails or if decoding fails.
  /// - Returns: A value of the specified decodable type.
  public func fetch<T: Decodable>(
    type: T.Type,
    with request: URLRequest,
    debugEnabled: Bool)
  async throws -> T
  {
    if debugEnabled {
      printCurlCommand(request)
    }
    // Convert URLRequest to HTTPRequest
    let httpRequest = try HTTPRequest(from: request)
    
    let (data, response) = try await httpClient.data(for: httpRequest)
    
    if debugEnabled {
      printHTTPResponse(response, data: data)
    }
    guard response.statusCode == 200 else {
      var errorMessage = "status code \(response.statusCode)"
      do {
        let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
        errorMessage += errorResponse.error.message
      } catch {
        // If decoding fails, proceed with a general error message
        errorMessage = "status code \(response.statusCode)"
      }
      throw APIError.responseUnsuccessful(description: errorMessage)
    }
#if DEBUG
    if debugEnabled {
      print("DEBUG JSON FETCH API = \(try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any])")
    }
#endif
    do {
      return try decoder.decode(type, from: data)
    } catch let DecodingError.keyNotFound(key, context) {
      let debug = "Key '\(key.stringValue)' not found: \(context.debugDescription)"
      let codingPath = "codingPath: \(context.codingPath)"
      let debugMessage = debug + codingPath
#if DEBUG
      if debugEnabled {
        print(debugMessage)
      }
#endif
      throw APIError.dataCouldNotBeReadMissingData(description: debugMessage)
    } catch {
#if DEBUG
      if debugEnabled {
        print("\(error)")
      }
#endif
      throw APIError.jsonDecodingFailure(description: error.localizedDescription)
    }
  }
  
  /// Asynchronously fetches a stream of decodable data types from Anthropic's API for chat completions.
  ///
  /// This method is primarily used for streaming chat completions.
  ///
  /// - Parameters:
  ///   - type: The `Decodable` type that each streamed response should be decoded to.
  ///   - request: The `URLRequest` describing the API request.
  ///   - debugEnabled: If true the service will print events on DEBUG builds.
  /// - Throws: An error if the request fails or if decoding fails.
  /// - Returns: An asynchronous throwing stream of the specified decodable type.
  public func fetchStream<T: Decodable>(
    type: T.Type,
    with request: URLRequest,
    debugEnabled: Bool)
  async throws -> AsyncThrowingStream<T, Error>
  {
    if debugEnabled {
      printCurlCommand(request)
    }
    
    // Convert URLRequest to HTTPRequest
    let httpRequest = try HTTPRequest(from: request)
    
    let (byteStream, response) = try await httpClient.bytes(for: httpRequest)
    
    if debugEnabled {
      printHTTPResponse(response)
    }
    guard response.statusCode == 200 else {
      var errorMessage = "status code \(response.statusCode)"
      // Note: We can't easily collect error data from the stream here
      // This is a limitation we accept for now
      throw APIError.responseUnsuccessful(description: errorMessage)
    }
    return AsyncThrowingStream { continuation in
      let task = Task {
        do {
          guard case .lines(let linesStream) = byteStream else {
            throw APIError.invalidData
          }
          for try await line in linesStream {
            // TODO: Test the `event` line
            if line.hasPrefix("data:"),
               let data = line.dropFirst(5).data(using: .utf8) {
#if DEBUG
              if debugEnabled {
                print("DEBUG JSON STREAM LINE = \(try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any])")
              }
#endif
              do {
                let decoded = try self.decoder.decode(T.self, from: data)
                continuation.yield(decoded)
              } catch let DecodingError.keyNotFound(key, context) {
                let debug = "Key '\(key.stringValue)' not found: \(context.debugDescription)"
                let codingPath = "codingPath: \(context.codingPath)"
                let debugMessage = debug + codingPath
#if DEBUG
                if debugEnabled {
                  print(debugMessage)
                }
#endif
                throw APIError.dataCouldNotBeReadMissingData(description: debugMessage)
              } catch {
#if DEBUG
                if debugEnabled {
                  debugPrint("CONTINUATION ERROR DECODING \(error.localizedDescription)")
                }
#endif
                continuation.finish(throwing: error)
              }
            }
          }
          continuation.finish()
        } catch let DecodingError.keyNotFound(key, context) {
          let debug = "Key '\(key.stringValue)' not found: \(context.debugDescription)"
          let codingPath = "codingPath: \(context.codingPath)"
          let debugMessage = debug + codingPath
#if DEBUG
          if debugEnabled {
            print(debugMessage)
          }
#endif
          throw APIError.dataCouldNotBeReadMissingData(description: debugMessage)
        } catch {
#if DEBUG
          if debugEnabled {
            print("CONTINUATION ERROR DECODING \(error.localizedDescription)")
          }
#endif
          continuation.finish(throwing: error)
        }
      }
      continuation.onTermination = { @Sendable _ in
        task.cancel()
      }
    }
  }
  
  // MARK: Debug Helpers
  
  private func prettyPrintJSON(
    _ data: Data)
  -> String?
  {
    guard
      let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
      let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
      let prettyPrintedString = String(data: prettyData, encoding: .utf8)
    else { return nil }
    return prettyPrintedString
  }
  
  private func printCurlCommand(
    _ request: URLRequest)
  {
    guard let url = request.url, let httpMethod = request.httpMethod else {
      debugPrint("Invalid URL or HTTP method.")
      return
    }
    
    var baseCommand = "curl \(url.absoluteString)"
    
    // Add method if not GET
    if httpMethod != "GET" {
      baseCommand += " -X \(httpMethod)"
    }
    
    // Add headers if any, masking the Authorization token
    if let headers = request.allHTTPHeaderFields {
      for (header, value) in headers {
        let maskedValue = header.lowercased() == "authorization" ? maskAuthorizationToken(value) : value
        baseCommand += " \\\n-H \"\(header): \(maskedValue)\""
      }
    }
    
    // Add body if present
    if let httpBody = request.httpBody, let bodyString = prettyPrintJSON(httpBody) {
      // The body string is already pretty printed and should be enclosed in single quotes
      baseCommand += " \\\n-d '\(bodyString)'"
    }
    
    // Print the final command
#if DEBUG
    print(baseCommand)
#endif
  }
  
  private func prettyPrintJSON(
    _ data: Data)
  -> String
  {
    guard
      let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
      let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
      let prettyPrintedString = String(data: prettyData, encoding: .utf8) else { return "Could not print JSON - invalid format" }
    return prettyPrintedString
  }
  
  private func printHTTPResponse(
    _ response: HTTPResponse,
    data: Data? = nil)
  {
#if DEBUG
    print("\n- - - - - - - - - - INCOMING RESPONSE - - - - - - - - - -\n")
    print("Status Code: \(response.statusCode)")
    print("Headers: \(response.headers)")
    if let data = data, let _ = response.headers["content-type"]?.contains("application/json") {
      print("Body: \(prettyPrintJSON(data))")
    } else if let data = data, let bodyString = String(data: data, encoding: .utf8) {
      print("Body: \(bodyString)")
    }
    print("\n- - - - - - - - - - - - - - - - - - - - - - - - - - - -\n")
#endif
  }
  
  private func maskAuthorizationToken(_ token: String) -> String {
    if token.count > 6 {
      let prefix = String(token.prefix(3))
      let suffix = String(token.suffix(3))
      return "\(prefix)................\(suffix)"
    } else {
      return "INVALID TOKEN LENGTH"
    }
  }
}
```

## Sources/Anthropic/Service/AnthropicServiceFactory.swift
```swift
//
//  AnthropicServiceFactory.swift
//
//
//  Created by James Rochabrun on 1/28/24.
//

import Foundation
#if os(Linux)
import FoundationNetworking
#endif


public final class AnthropicServiceFactory {
  
  /// Creates and returns an instance of `AnthropicService`.
  ///
  /// - Parameters:
  ///   - apiKey: The API key required for authentication.
  ///   - apiVersion: The Anthropic api version. Currently "2023-06-01". (Can be overriden)
  ///   - basePath: An overridable base path for requests, defaults to https://api.anthropic.com
  ///   - betaHeaders: An array of headers for Anthropic's beta features.
  ///   - httpClient: The HTTP client to be used for network calls (default creates platform-appropriate client).
  ///   - debugEnabled: If `true` service prints event on DEBUG builds, default to `false`.
  ///
  /// - Returns: A fully configured object conforming to `AnthropicService`.
  public static func service(
    apiKey: String,
    apiVersion: String = "2023-06-01",
    basePath: String = "https://api.anthropic.com",
    betaHeaders: [String]?,
    httpClient: HTTPClient? = nil,
    debugEnabled: Bool = false)
    -> AnthropicService
  {
    DefaultAnthropicService(
      apiKey: apiKey,
      apiVersion: apiVersion,
      basePath: basePath,
      betaHeaders: betaHeaders,
      httpClient: httpClient ?? HTTPClientFactory.createDefault(),
      debugEnabled: debugEnabled)
  }
  
#if !os(Linux)
  /// Creates and returns an instance of `AnthropicService`.
  ///
  /// - Parameters:
  ///   - aiproxyPartialKey: The partial key provided in the 'API Keys' section of the AIProxy dashboard.
  ///                        Please see the integration guide for acquiring your key, at https://www.aiproxy.pro/docs
  ///
  ///   - aiproxyServiceURL: The service URL is displayed in the AIProxy dashboard when you submit your Anthropic key.
  ///
  ///   - aiproxyClientID: If your app already has client or user IDs that you want to annotate AIProxy requests
  ///                      with, you can pass a clientID here. If you do not have existing client or user IDs, leave
  ///                      the `clientID` argument out, and IDs will be generated automatically for you.
  ///
  ///   - apiVersion: The Anthropic api version. Currently "2023-06-01". (Can be overriden)
  ///   - betaHeaders: An array of headers for Anthropic's beta features.
  ///   - debugEnabled: If `true` service prints event on DEBUG builds, default to `false`.
  ///
  /// - Returns: A conformer of `AnthropicService` that proxies all requests through api.aiproxy.pro
  public static func service(
    aiproxyPartialKey: String,
    aiproxyServiceURL: String,
    aiproxyClientID: String? = nil,
    apiVersion: String = "2023-06-01",
    betaHeaders: [String]?,
    debugEnabled: Bool = false)
    -> AnthropicService
  {
    AIProxyService(
      partialKey: aiproxyPartialKey,
      serviceURL: aiproxyServiceURL,
      clientID: aiproxyClientID,
      apiVersion: apiVersion,
      betaHeaders: betaHeaders,
      debugEnabled: debugEnabled)
  }
#endif
  
}
```

## Sources/Anthropic/Service/DefaultAnthropicService.swift
```swift
//
//  DefaultAnthropicService.swift
//
//
//  Created by James Rochabrun on 1/28/24.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct DefaultAnthropicService: AnthropicService {
  
  let httpClient: HTTPClient
  let decoder: JSONDecoder
  let apiKey: String
  let apiVersion: String
  let basePath: String
  let betaHeaders: [String]?
  /// Set this flag to TRUE if you need to print request events in DEBUG builds.
  private let debugEnabled: Bool
  
  init(
    apiKey: String,
    apiVersion: String = "2023-06-01",
    basePath: String,
    betaHeaders: [String]?,
    httpClient: HTTPClient,
    debugEnabled: Bool)
  {
    self.httpClient = httpClient
    let decoderWithSnakeCaseStrategy = JSONDecoder()
    decoderWithSnakeCaseStrategy.keyDecodingStrategy = .convertFromSnakeCase
    self.decoder = decoderWithSnakeCaseStrategy
    self.apiKey = apiKey
    self.apiVersion = apiVersion
    self.basePath = basePath
    self.betaHeaders = betaHeaders
    self.debugEnabled = debugEnabled
  }
  
  // MARK: Message
  
  func createMessage(
    _ parameter: MessageParameter)
  async throws -> MessageResponse
  {
    var localParameter = parameter
    localParameter.stream = false
    let request = try AnthropicAPI(base: basePath, apiPath: .messages).request(apiKey: apiKey, version: apiVersion, method: HTTPMethod.post, params: localParameter, betaHeaders: betaHeaders)
    return try await fetch(type: MessageResponse.self, with: request, debugEnabled: debugEnabled)
  }
  
  func streamMessage(
    _ parameter: MessageParameter)
  async throws -> AsyncThrowingStream<MessageStreamResponse, Error>
  {
    var localParameter = parameter
    localParameter.stream = true
    let request = try AnthropicAPI(base: basePath, apiPath: .messages).request(apiKey: apiKey, version: apiVersion, method: HTTPMethod.post, params: localParameter, betaHeaders: betaHeaders)
    return try await fetchStream(type: MessageStreamResponse.self, with: request, debugEnabled: debugEnabled)
  }
  
  func countTokens(
    parameter: MessageTokenCountParameter)
  async throws -> MessageInputTokens
  {
    let request = try AnthropicAPI(base: basePath, apiPath: .countTokens).request(apiKey: apiKey, version: apiVersion, method: HTTPMethod.post, params: parameter, betaHeaders: betaHeaders)
    return try await fetch(type: MessageInputTokens.self, with: request, debugEnabled: debugEnabled)
  }
  
  /// "messages-2023-12-15"
  // MARK: Text Completion
  
  func createTextCompletion(
    _ parameter: TextCompletionParameter)
  async throws -> TextCompletionResponse
  {
    var localParameter = parameter
    localParameter.stream = false
    let request = try AnthropicAPI(base: basePath, apiPath: .textCompletions).request(apiKey: apiKey, version: apiVersion, method: HTTPMethod.post, params: localParameter)
    return try await fetch(type: TextCompletionResponse.self, with: request, debugEnabled: debugEnabled)
  }
  
  func createStreamTextCompletion(
    _ parameter: TextCompletionParameter)
  async throws -> AsyncThrowingStream<TextCompletionStreamResponse, Error>
  {
    var localParameter = parameter
    localParameter.stream = true
    let request = try AnthropicAPI(base: basePath, apiPath: .textCompletions).request(apiKey: apiKey, version: apiVersion, method: HTTPMethod.post, params: localParameter)
    return try await fetchStream(type: TextCompletionStreamResponse.self, with: request, debugEnabled: debugEnabled)
  }
  
}
```

## Tests/SwiftAnthropicTests/SwiftAnthropicTests.swift
```swift
import XCTest
@testable import SwiftAnthropic

final class SwiftAnthropicTests: XCTestCase {
    func testEndpointConstruction() throws {
       let endpoint = AnthropicAPI(
         base: "https://api.example.org/my/path",
         apiPath: .messages
       )
       let comp = endpoint.urlComponents(
         queryItems: [URLQueryItem(name: "query", value: "value")]
       )
       XCTAssertEqual(
         "https://api.example.org/my/path/v1/messages?query=value",
         comp.url!.absoluteString
       )
    }
}
```

## Examples/SwiftAnthropicExample/SwiftAnthropicExample/AIProxyIntroView.swift
```swift
//
//  AIProxyIntroView.swift
//  SwiftAnthropicExample
//
//  Created by Lou Zell on 7/31/24.
//

import SwiftUI
import SwiftAnthropic

struct AIProxyIntroView: View {

   @State private var partialKey = ""
   @State private var serviceURL = ""

   private var canProceed: Bool {
      return !(self.partialKey.isEmpty || self.serviceURL.isEmpty)
   }

   var body: some View {
      NavigationStack {
         VStack {
            Spacer()
            VStack(spacing: 24) {
               TextField("Enter partial key", text: $partialKey)
               TextField("Enter your service's URL", text: $serviceURL)
            }
            .padding()
            .textFieldStyle(.roundedBorder)

            Text("You receive a partial key and service URL when you configure an app in the AIProxy dashboard")
               .font(.caption)

            NavigationLink(destination: OptionsListView(service: aiproxyService)) {
               Text("Continue")
                  .padding()
                  .padding(.horizontal, 48)
                  .foregroundColor(.white)
                  .background(
                     Capsule()
                        .foregroundColor(canProceed ? Color(red: 186/255, green: 91/255, blue: 55/255) : .gray.opacity(0.2)))
            }
            .disabled(!canProceed)
            Spacer()
            Group {
               Text("AIProxy keeps your Anthropic API key secure. To configure AIProxy for your project, or to learn more about how it works, please see the docs at ") + Text("[this link](https://www.aiproxy.pro/docs).")
            }
            .font(.caption)
         }
         .padding()
         .navigationTitle("AIProxy Configuration")
      }
   }

   private var aiproxyService: AnthropicService {
      return AnthropicServiceFactory.service(
         aiproxyPartialKey: partialKey,
         aiproxyServiceURL: serviceURL, 
         betaHeaders: ["max-tokens-3-5-sonnet-2024-07-15", "prompt-caching-2024-07-31"]
      )
   }
}

#Preview {
   ApiKeyIntroView()
}
```

## Examples/SwiftAnthropicExample/SwiftAnthropicExample/ApiKeyIntroView.swift
```swift
//
//  ApiKeyIntroView.swift
//  SwiftAnthropicExample
//
//  Created by James Rochabrun on 2/24/24.
//

import SwiftUI
import SwiftAnthropic

struct ApiKeyIntroView: View {
   
   @State private var apiKey = ""
   
   var body: some View {
      NavigationStack {
         VStack {
            Spacer()
            VStack(spacing: 24) {
               TextField("Enter API Key", text: $apiKey)
            }
            .padding()
            .textFieldStyle(.roundedBorder)
            NavigationLink(destination: OptionsListView(service: AnthropicServiceFactory.service(
               apiKey: apiKey,
               betaHeaders: ["prompt-caching-2024-07-31", "max-tokens-3-5-sonnet-2024-07-15"], debugEnabled: true))) {
               Text("Continue")
                  .padding()
                  .padding(.horizontal, 48)
                  .foregroundColor(.white)
                  .background(
                     Capsule()
                        .foregroundColor(apiKey.isEmpty ? .gray.opacity(0.2) : Color(red: 186/255, green: 91/255, blue: 55/255)))
            }
            .disabled(apiKey.isEmpty)
            Spacer()
            Group {
               Text("You can find a blog post in how to use the `SwiftAnthropic` Package ") +  Text("[here](https://medium.com/@jamesrochabrun/anthropic-ios-sdk-032e1dc6afd8)")
               Text("If you don't have a valid API KEY yet, you can visit ") + Text("[this link](https://www.anthropic.com/earlyaccess)") + Text(" to get started.")
            }
            .font(.caption)
         }
         .padding()
         .navigationTitle("Enter Anthropic API KEY")
      }
   }
}

#Preview {
   ApiKeyIntroView()
}
```

## Examples/SwiftAnthropicExample/SwiftAnthropicExample/FunctionCalling/MessageFunctionCallingDemoView.swift
```swift
//
//  MessageFunctionCallingDemoView.swift
//
//
//  Created by James Rochabrun on 4/4/24.
//

import Foundation
import PhotosUI
import SwiftAnthropic
import SwiftUI

enum FunctionCallDefinition: String, CaseIterable {
   
   case getWeather = "get_weather"
   // Add more functions if needed, parallel function calling is supported.

   var tool: MessageParameter.Tool {
      switch self {
      case .getWeather:
         return .function(
            name: self.rawValue,
            description: "Get the current weather in a given location",
            inputSchema: .init(
                           type: .object,
                           properties: [
                              "location": .init(type: .string, description: "The city and state, e.g. San Francisco, CA"),
                              "unit": .init(type: .string, description: "The unit of temperature, either celsius or fahrenheit")
                           ],
                           required: ["location"]))
      }
   }
}

@MainActor
struct MessageFunctionCallingDemoView: View {
   
   let observable: MessageFunctionCallingObservable
   @State private var selectedSegment: ChatConfig = .messageStream
   @State private var prompt = ""
   
   @State private var selectedItems: [PhotosPickerItem] = []
   @State private var selectedImages: [Image] = []
   @State private var selectedImagesEncoded: [String] = []

   enum ChatConfig {
      case message
      case messageStream
   }
   
   var body: some View {
      ScrollView {
         VStack {
            Text("TOOL: Web search")
            picker
            Text(observable.errorMessage)
               .foregroundColor(.red)
            messageView
         }
         .padding()
      }
      .overlay(
         Group {
            if observable.isLoading {
               ProgressView()
            } else {
               EmptyView()
            }
         }
      ).safeAreaInset(edge: .bottom) {
         VStack(spacing: 0) {
            selectedImagesView
            textArea
         }
      }
   }
   
   var textArea: some View {
      HStack(spacing: 4) {
         TextField("Enter prompt", text: $prompt, axis: .vertical)
            .textFieldStyle(.roundedBorder)
            .padding()
         photoPicker
         Button {
            Task {
               
               let images: [MessageParameter.Message.Content.ContentObject] = selectedImagesEncoded.map {
                  .image(.init(type: .base64, mediaType: .jpeg, data: $0))
               }
               let text: [MessageParameter.Message.Content.ContentObject] = [.text(prompt)]
               
               let finalInput = images + text
               
               let messages = [MessageParameter.Message(role: .user, content: .list(finalInput))]
               
               prompt = ""
               
               let webSearchTool = MessageParameter.webSearch(
                  maxUses: 5,
                  allowedDomains: ["wikipedia.org"],
                  userLocation: .sanFrancisco
               )
               
               let parameters = MessageParameter(
                  model: .claude35Sonnet,
                  messages: messages,
                  maxTokens: 1024, 
                  tools: [webSearchTool])
               switch selectedSegment {
               case .message:
                  try await observable.createMessage(parameters: parameters)
               case .messageStream:
                  try await observable.streamMessage(parameters: parameters)
               }
            }
         } label: {
            Image(systemName: "paperplane")
         }
         .buttonStyle(.bordered)
      }
      .padding()
   }
   
   var picker: some View {
      Picker("Options", selection: $selectedSegment) {
         Text("Message").tag(ChatConfig.message)
         Text("Message Stream").tag(ChatConfig.messageStream)
      }
      .pickerStyle(SegmentedPickerStyle())
      .padding()
   }
   
   var messageView: some View {
      VStack(spacing: 24) {
         HStack {
            Button("Cancel") {
               observable.cancelStream()
            }
            Button("Clear Message") {
               observable.clearMessage()
            }
         }
         Text(observable.message)
         if let toolResponse = observable.toolUse {
            Divider()
            VStack {
               Text("Tool use")
                  .bold()
               Text("Name: \(toolResponse.name)")
               Text("ID: \(toolResponse.id)")
               if !toolResponse.inputDisplay.isEmpty {
                  Text("Input: \(toolResponse.inputDisplay)")
               }
            }
         }
         
         if !observable.totalJson.isEmpty {
            VStack {
               Divider()
               Text("Stream response tool use Json.")
               Text(observable.totalJson)
            }
         }
      }
      .buttonStyle(.bordered)
   }
   
   var photoPicker: some View {
      PhotosPicker(selection: $selectedItems, matching: .images) {
         Image(systemName: "photo")
      }
      .onChange(of: selectedItems) {
         Task {
            selectedImages.removeAll()
            for item in selectedItems {
               
               if let data = try? await item.loadTransferable(type: Data.self) {
                  if let uiImage = UIImage(data: data), let resizedImageData = uiImage.jpegData(compressionQuality: 0.7) {
                      // Make sure the resized image is below the size limit
                     // This is needed as Claude allows a max of 5Mb size per image.
                      if resizedImageData.count < 5_242_880 { // 5 MB in bytes
                          let base64String = resizedImageData.base64EncodedString()
                          selectedImagesEncoded.append(base64String)
                          let image = Image(uiImage: UIImage(data: resizedImageData)!)
                          selectedImages.append(image)
                      } else {
                          // Handle the error - maybe resize to an even smaller size or show an error message to the user
                      }
                  }
               }
            }
         }
      }
   }
   
   var selectedImagesView: some View {
      HStack(spacing: 0) {
         ForEach(0..<selectedImages.count, id: \.self) { i in
            selectedImages[i]
               .resizable()
               .frame(width: 60, height: 60)
               .clipShape(RoundedRectangle(cornerRadius: 12))
               .padding(4)
         }
      }
   }
}
```

## Examples/SwiftAnthropicExample/SwiftAnthropicExample/FunctionCalling/MessageFunctionCallingObservable.swift
```swift
//
//  MessageFunctionCallingObservable.swift
//
//
//  Created by James Rochabrun on 4/4/24.
//

import Foundation
import SwiftAnthropic
import SwiftUI

@MainActor
@Observable class MessageFunctionCallingObservable {
   
   let service: AnthropicService
   var errorMessage = ""
   var isLoading = false
   var message = ""
   var thinking = ""
   
   var toolUse: MessageResponse.Content.ToolUse?
   
   // Stream tool use response
   var totalJson: String = ""
   
   init(service: AnthropicService) {
      self.service = service
   }
   
   func createMessage(
      parameters: MessageParameter) async throws
   {
      task = Task {
         do {
            isLoading = true
            let message = try await service.createMessage(parameters)
            isLoading = false
            for content in message.content {
               switch content {
               case .text(let text, _):
                  self.message = text
               case .toolUse(let toolUSe):
                  toolUse = toolUSe
               case .thinking(let thinking):
                  self.thinking = thinking.thinking
               case .serverToolUse(let serverToolUse):
                  dump(serverToolUse)
               case .webSearchToolResult(let webSearchTool):
                  dump(webSearchTool)
               case .toolResult(let toolResult):
                 dump(toolResult)
               }
            }
         } catch {
            self.errorMessage = "\(error)"
         }
      }
   }
   
   func streamMessage(
      parameters: MessageParameter) async throws
   {
      task = Task {
         do {
            isLoading = true
            let stream = try await service.streamMessage(parameters)
            isLoading = false
            for try await result in stream {
               
               let content = result.delta?.text ?? ""
               self.message += content
               
               /// PartialJson is the JSON provided by tool use. Clients need to accumulate it.
               /// https://docs.anthropic.com/en/api/messages-streaming#input-json-delta
               self.totalJson += result.delta?.partialJson ?? ""
               
               switch result.streamEvent {
               case .contentBlockStart:
                  // Tool use data is only available in `content_block_start` events.
                  /*
                   event: content_block_start
                   data: {"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"toolu_01KXkhDdRhvV1pnk23GiWmjo","name":"get_weather","input":{}} }
                   */
                  self.toolUse = result.contentBlock?.toolUse
               default: break
               }
            }
         } catch {
            self.errorMessage = "\(error)"
         }
      }
   }
   
   func cancelStream() {
      task?.cancel()
   }
   
   func clearMessage() {
      message = ""
      toolUse = nil
      totalJson = ""
   }
   
   // MARK: Private
   
   private var task: Task<Void, Never>? = nil
   
}

extension MessageResponse.Content.ToolUse {
   
   var inputDisplay: String {
      var display = ""
      for key in input.keys {
         display += key
         display += ","
         switch input[key] {
         case .string(let text):
            display += text
         default: break
         }
      }
      return display
   }
}
```

## Examples/SwiftAnthropicExample/SwiftAnthropicExample/Messages/MessageDemoObservable.swift
```swift
//
//  MessageDemoObservable.swift
//  SwiftAnthropicExample
//
//  Created by James Rochabrun on 2/24/24.
//

import Foundation
import SwiftAnthropic
import SwiftUI

@MainActor
@Observable class MessageDemoObservable {
   
   let service: AnthropicService
   var message: String = ""
   var errorMessage: String = ""
   var isLoading = false
   var selectedPDF: Data? = nil
   var inputTokensCount: String?
   
   init(service: AnthropicService) {
      self.service = service
   }
   
   func createMessage(
      parameters: MessageParameter) async throws
   {
      task = Task {
         do {
            isLoading = true
            let message = try await service.createMessage(parameters)
            isLoading = false
            switch message.content.first {
            case .text(let text, let citations):
               // We need to concatenate the text response.
               self.message = text
               if let citations {
                  dump(citations)
               }
            default:
               /// Function call not implemented on this demo
               break
            }
         } catch {
            self.errorMessage = "\(error)"
         }
      }
   }
   
   func streamMessage(
      parameters: MessageParameter) async throws
   {
      task = Task {
         do {
            var citationCitedText = ""
            isLoading = true
            let stream = try await service.streamMessage(parameters)
            isLoading = false
            for try await result in stream {
               let content = result.delta?.text ?? ""
               self.message += content
               switch result.delta?.citation {
               case .charLocation(let charLocation):
                  citationCitedText += charLocation.citedText ?? ""
               case .contentBlockLocation(let blockLocation):
                  citationCitedText += blockLocation.citedText ?? ""
               case .pageLocation(let pageLocation):
                  citationCitedText += pageLocation.citedText ?? ""
               default: break
               }
            }
            if !citationCitedText.isEmpty {
               debugPrint("Citation Text: \n \(citationCitedText)")
            }
         } catch {
            self.errorMessage = "\(error)"
         }
      }
   }
   
   func countTokens(parameters: MessageTokenCountParameter) async throws {
      let inputTokens = try await service.countTokens(parameter: parameters)
      inputTokensCount = "\(inputTokens.inputTokens)"
   }
   
   func analyzePDF(prompt: String, selectedSegment: MessageDemoView.ChatConfig) async throws {
      guard let pdfData = selectedPDF else {
         errorMessage = "No PDF selected"
         return
      }
      
      // Convert PDF to base64
      let base64PDF = pdfData.base64EncodedString()
      
      do {
         // Create document source with citations enabled
         let documentSource = try MessageParameter.Message.Content.DocumentSource.pdf(base64Data: base64PDF, citations: .init(enabled: true))
         
         // Create message with document and prompt
         let message = MessageParameter.Message(
            role: .user,
            content: .list([
               .document(documentSource),
               .text(prompt.isEmpty ? "Please analyze this document and provide a summary" : prompt)
            ])
         )
         
         // Create parameters
         let parameters = MessageParameter(
            model: .claude35Sonnet,
            messages: [message],
            maxTokens: 1024
         )
         
         // Send request based on selected mode
         switch selectedSegment {
         case .message:
            try await createMessage(parameters: parameters)
         case .messageStream:
            try await streamMessage(parameters: parameters)
         }
         
      } catch MessageParameter.Message.Content.DocumentSource.DocumentError.exceededSizeLimit {
         errorMessage = "PDF exceeds size limit (32MB)"
      } catch MessageParameter.Message.Content.DocumentSource.DocumentError.invalidBase64Data {
         errorMessage = "Invalid PDF data"
      } catch {
         errorMessage = "Error analyzing PDF: \(error.localizedDescription)"
      }
   }
   
   func cancelStream() {
      task?.cancel()
   }
   
   func clearMessage() {
      message = ""
      selectedPDF = nil
      errorMessage = ""
   }
   
   // MARK: Private
   private var task: Task<Void, Never>? = nil
   // Track the current active content block
   private var currentThinking = ""
   private var currentBlockType: String?
   private var currentBlockIndex: Int?
}
```

## Examples/SwiftAnthropicExample/SwiftAnthropicExample/Messages/MessageDemoView.swift
```swift
//
//  MessageDemoView.swift
//  SwiftAnthropicExample
//
//  Created by James Rochabrun on 2/24/24.
//

import SwiftUI
import PhotosUI
import SwiftAnthropic
import UniformTypeIdentifiers

@MainActor
struct MessageDemoView: View {
   
   let observable: MessageDemoObservable
   @State private var selectedSegment: ChatConfig = .messageStream
   @State private var prompt = ""
   
   @State private var selectedItems: [PhotosPickerItem] = []
   @State private var selectedImages: [Image] = []
   @State private var selectedImagesEncoded: [String] = []
   @State private var showingDocumentPicker = false
   
   enum ChatConfig {
      case message
      case messageStream
   }
   
   var body: some View {
      ScrollView {
         VStack {
            picker
            Text(observable.errorMessage)
               .foregroundColor(.red)
            if let inputTokensCount = observable.inputTokensCount {
               Text("Tokens: \(inputTokensCount)")
            }
            messageView
         }
         .padding()
      }
      .overlay(
         Group {
            if observable.isLoading {
               ProgressView()
            } else {
               EmptyView()
            }
         }
      )
      .safeAreaInset(edge: .bottom) {
         VStack(spacing: 0) {
            selectedImagesView
            if observable.selectedPDF != nil {
               HStack {
                  Image(systemName: "doc.fill")
                  Text("PDF Selected")
                  Button(action: { observable.selectedPDF = nil }) {
                     Image(systemName: "xmark.circle.fill")
                  }
               }
               .padding()
            }
            textArea
         }
      }
      .fileImporter(
         isPresented: $showingDocumentPicker,
         allowedContentTypes: [UTType.pdf],
         allowsMultipleSelection: false
      ) { result in
         switch result {
         case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
               let pdfData = try Data(contentsOf: url)
               // Check size limit (32MB)
               guard pdfData.count <= 32_000_000 else {
                  observable.errorMessage = "PDF exceeds size limit (32MB)"
                  return
               }
               observable.selectedPDF = pdfData
            } catch {
               observable.errorMessage = "Error loading PDF: \(error.localizedDescription)"
            }
         case .failure(let error):
            observable.errorMessage = error.localizedDescription
         }
      }
   }
   
   var textArea: some View {
      HStack(spacing: 4) {
         TextField("Enter prompt", text: $prompt, axis: .vertical)
            .textFieldStyle(.roundedBorder)
            .padding()
         
         Button(action: { showingDocumentPicker = true }) {
            Image(systemName: "doc.badge.plus")
         }
         .buttonStyle(.bordered)
         
         photoPicker
         
         Button {
            Task {
               if observable.selectedPDF != nil {
                  try await observable.analyzePDF(prompt: prompt, selectedSegment: selectedSegment)
               } else {
                  let images: [MessageParameter.Message.Content.ContentObject] = selectedImagesEncoded.map {
                     .image(.init(type: .base64, mediaType: .jpeg, data: $0))
                  }
                  let text: [MessageParameter.Message.Content.ContentObject] = [.text(prompt)]
                  let finalInput = images + text
                  
                  let messages = [MessageParameter.Message(role: .user, content: .list(finalInput))]
                  
                  prompt = ""
                  let parameters = MessageParameter(
                     model: .claude35Sonnet,
                     messages: messages,
                     maxTokens: 1024
                  )
                  
                  // Input Tokens count
                  let messageTokenCountParameter = MessageTokenCountParameter(model: .claude35Sonnet, messages: messages)
                  try await observable.countTokens(parameters: messageTokenCountParameter)
                  
                  switch selectedSegment {
                  case .message:
                     try await observable.createMessage(parameters: parameters)
                  case .messageStream:
                     try await observable.streamMessage(parameters: parameters)
                  }
               }
            }
         } label: {
            Image(systemName: "paperplane")
         }
         .buttonStyle(.bordered)
      }
      .padding()
   }
   
   var picker: some View {
      Picker("Options", selection: $selectedSegment) {
         Text("Message").tag(ChatConfig.message)
         Text("Message Stream").tag(ChatConfig.messageStream)
      }
      .pickerStyle(SegmentedPickerStyle())
      .padding()
   }
   
   var messageView: some View {
      VStack(spacing: 24) {
         HStack {
            Button("Cancel") {
               observable.cancelStream()
            }
            Button("Clear Message") {
               observable.clearMessage()
               selectedImages.removeAll()
               selectedImagesEncoded.removeAll()
               selectedItems.removeAll()
               prompt = ""
            }
         }
         Text(observable.message)
      }
      .buttonStyle(.bordered)
   }
   
   var photoPicker: some View {
      PhotosPicker(selection: $selectedItems, matching: .images) {
         Image(systemName: "photo")
      }
      .onChange(of: selectedItems) {
         Task {
            selectedImages.removeAll()
            selectedImagesEncoded.removeAll()
            for item in selectedItems {
               if let data = try? await item.loadTransferable(type: Data.self) {
                  if let uiImage = UIImage(data: data), let resizedImageData = uiImage.jpegData(compressionQuality: 0.7) {
                     // Make sure the resized image is below the size limit
                     // This is needed as Claude allows a max of 5Mb size per image.
                     if resizedImageData.count < 5_242_880 { // 5 MB in bytes
                        let base64String = resizedImageData.base64EncodedString()
                        selectedImagesEncoded.append(base64String)
                        let image = Image(uiImage: UIImage(data: resizedImageData)!)
                        selectedImages.append(image)
                     } else {
                        observable.errorMessage = "Image exceeds 5MB size limit after compression"
                     }
                  }
               }
            }
         }
      }
   }
   
   var selectedImagesView: some View {
      HStack(spacing: 0) {
         ForEach(0..<selectedImages.count, id: \.self) { i in
            selectedImages[i]
               .resizable()
               .frame(width: 60, height: 60)
               .clipShape(RoundedRectangle(cornerRadius: 12))
               .padding(4)
         }
      }
   }
}


let videoTranscription = """
Hello, my name is Srividya Karumuri and I'm a GPU Compiler Engineer at Apple. Today I'm here to share some tips that can improve the performance of your Metal shaders.

The new Apple Family 9 GPU in M3 and A17 Pro have some new advancements that you could apply to your application. I have some recommendations for Apple Family 9 GPUs. In addition to guidance tips and tricks that apply to all Apple GPU generations.

You can improve your shader's performance by reducing their runtime with features in the Metal shading language, increasing parallelism by improving resource utilization from the shader, and making the most of the ray tracing acceleration hardware in the Apple Family 9 GPUs.

Metal has several features that can minimize the shader's runtime including, function constants, which can efficiently specialize a shader, function groups which can optimize shaders using indirect function calls.

The Metal function constants features specializes the shader efficiently and removes the code that isn't reachable at runtime. For example, uber shaders typically benefit from function constants.

An uber shader is often complex because it can handle many different possibilities at runtime, such as rendering different material types in a 3D application.

Developers sometimes make uber shaders that read material parameters from a buffer and then a material shader chooses different control parts at runtime based on the buffer's contents.

This approach lets the shader render a new material effect without recompiling because the only changes are parameters in the buffer.

For example, this uber shader in a pipeline renders a glossy material because a Metal buffer in the draw command has an is_glossy parameter that's equal to true. The same shader can also render a matte material when the buffer's is_glossy parameter is equal to false.

The render pipeline is the same for both material effects because the behavior change comes from what's in the buffer.

This responsive approach is great during development, however, the shader has to account for several possibilities and read from additional buffers which may affect an app's performance. Another approach is to specialize the shader at compile time instead of at runtime. By building the shader variance offline with preprocessor macros.

This is an uber shader specialized using macros. Each specialized shader has its own render pipeline and only has the code it needs for rendering a specific material effect.

This approach means you have to compile all the possible variant combinations offline. For example, a glossy variant could be the combination of enabling both is_glossy and use_shadows macros, by disabling the remaining macros.

Similarly, a matte function variant could be a combination of the use_shadows and has_reflections macros.

And a glossy reflections variant enables the is_glossy and has_reflections macros and so on.

Implementing an uber shader with macros can mean compiling a large number of variants, such as one variant for each possible macro combination. Some of which your app may never use.

Even if you compile them offline ahead of time, each variant adds up which can significantly increase the size of your Metal library. It can also increase compile time because each shade of variant has to be compiled starting from Metal source.

Function constants can provide another way to specialize the shaders. Compared to using macros, it can reduce both compile time and the size of the Metal library. With function constants, you compile an uber shader one time from source to an intermediate Metal function. From that function, you only create the variance your app needs based on function constants you define.

Function constants give you the flexibility to both create multiple specialized variants on the go as needed and reuse an intermediate Metal function for all remaining possibilities.

With this approach, you can save time and space by creating only the shader variance and render pipelines you need.

You can create these specialized variance by declaring function constants in your Metal function code and then defining each of their values as you create Metal functions.

You can also use function constants to initialize program scope variables that you declare in the constant address space.

You can enable different code parts in the shader with these function constants instead of reading values from Metal buffers.

With function constants, Metal can fold these as constant Booleans as it compiles the shader's specialization variant, as well as other optimizations, such as eliminating unreachable code parts.

And that can remove unused control flow.

By specializing shader with function constants, you don't need to query material parameters from buffers anymore. This approach reduces the shaders runtime by simplifying its control flow and removing unused code parts. I encourage you to watch, "Optimize GPU renders with Metal," which goes over the details on how to set function constant values at runtime. It also goes over how to mitigate the runtime compilation overhead with a synchronous compilation.

You can also reduce your shaders runtime by adding the function group's attribute for indirect function calls.

An indirect function is a function the shader calls without directly invoking by its name, such as with function pointers or visible function tables. A shader can call an indirect function through static or dynamic linking, indirect function calls make the code extensible and give your app more options for flexibility. However, indirect function calls can prevent Metal from fully optimizing the shader, especially around the call site.

For statically linked functions, you can use the Metal function group's feature, which lets Metal optimize the shader with indirect function calls.

This shader invokes three different indirect functions including calls through function pointers for lighting, and a material. Metal can't optimize across these function pointer call sites because it has no visibility which functions the shader is calling. However, when you know that the function pointers can only point to one of the specific group of functions, you can use the function group's attribute. For example, the only functions the shader could call are all the linked functions in the shaders pipeline state, and you may know that the lighting function can only invoke the area, spot or sphere functions. In that case, you can group these functions into your lighting function group. Similarly, if the material function pointer can only invoke the wood, glass or metal functions, then you can group them into your material function group. You can give Metal a hint on how to optimize an indirect call by adding the function group's attribute at the call site.

You define the function groups by assigning a dictionary to a linked functions group's property. Each dictionary entry is a string key, which is the name of the function group, and the value is an area of functions that belong to that group. Note that this approach only helps for functions that you statically link, functions you compile to a binary library will not benefit from this.

Check out these two videos to learn more about the Metal function pointers and the various compilation workflows.

In summary, two ways to reduce a shader's runtime are function constants, which can create a specialized variant of the shader efficiently, and function groups that can optimize the shader where it invokes indirect functions.

Having looked at some Metal features that can reduce the shader's execution time, let's see some ways to improve the resource utilization leading to increased parallelism.

Increasing the thread occupancy is very important to improve latency hiding in shader execution. Thread occupancy really depends on the amount of available resources, be it registers or memory. So optimized usage of data from the shader can increase thread occupancy. Apple Family 9 GPUs have new advancements related to occupancy management. For more details, please check out, "Explore GPU advancements in M3 and A17 Pro." And to learn how to triage the lower thread occupancy bottlenecks, please check out, "Discover new Metal profiling tools for M3 and A17 Pro." The address space of memory objects and the data type used in ALU operations can impact the resource utilization.

Choosing the right address space for a memory object is very important for better memory utilization and to improve the thread occupancy.

In Metal shading language, address spaces are designed to support different access patterns and to specify the region of memory from where memory objects are allocated.

Picking the right address space will directly impact the performance of shaders. We are going to focus our attention on constant device and threadgroup address spaces. Constant address space allows you to create memory objects that are read only.

These accesses are optimized for data that is constant across all thread software dispatch or draw.

If the size of the object is fixed, and if the object is read many times by different threads, then create those objects in constant address space.

You can create read/write buffers in device address space. If the data being accessed is varying across the threads or if the size of the buffer is not fixed, then you can create such buffers in device address space.

Check out, "Optimize Metal Performance for Apple silicon Macs," for more details on constant and device address space recommendations with examples.

Threadgroup address space is for read/write memory objects too. Threads in the threadgroup can work together by sharing data in the threadgroup memory.

They're often faster in most cases.

In some use cases, threadgroup memory is used as a software-managed cache of device or constant buffers. For example, blocks of device memory are copied into threadgroup memory to operate with. It can be faster in some cases.

With the new advancements in Apple Family 9 GPUs shader code memory, the trade-offs on when to use threadgroup memory might be different from prior GPUs.

In your shader, if the use of threadgroup memory is primarily to use as a software-managed cache of device or constant buffers, then it may be more performant to read directly from those buffers instead of copying to threadgroup memory.

With Apple Family 9 GPUs dynamic shader core memory and flexible on-chip memory features, threadgroup device constant memory types are using the same cache hierarchy, so if your working set size fits in the cache, then both the buffer and threadgroup memory access might have similar performance characteristics. In those cases, instead of creating copies of memory in threadgroup and device or constant address space, shader can just operate with the device or constant buffers and avoid the latencies involved with copying to threadgroup memory.

Additional guidance on whether keeping the data just in device or constant buffers is beneficial or not, can be evaluated by profiling the workload using Metal debugger in Xcode.

Similar to address-based selection, data type can impact the performance too. For instance, 16-bit data types can help reduce the register and memory footprint.

Using 16-bit data types such as half and short over float and int when possible allows better performance. Conversions are free, so don't worry about converting between types such as between half and float. Bfloat is a 16-bit truncated version of float best suited for accelerating machine learning applications.

It allows wide range of values at a lower precision Bfloat data type has been supported since Metal 3.1. If your application has precision requirements that match with what is supported by bfloat, it is highly recommended to use this data type.

Using 16-bit data types rather than 32-bit data types results in shader using fewer registers. If that data is stored in memory, it can also help reduce the memory footprint and improve bandwidth. As a result, it can lead to better thread occupancy. Using 16-bit data types also improves the energy efficiency.

When writing expressions that are meant to be evaluated at half decision, be sure to use 'h' suffix on any literals. Otherwise, the entire expression will be evaluated at a float precision and that will lose the benefits of using smaller types.

In some shaders, it can result in better instruction mix by using half type, such as having a mix of float, half and int type instructions. This can result in better utilization of ALU pipelines in Apple Family 9 GPU, and it can improve the instruction throughput.

To summarize, improve resource utilization by choosing the right address space based on the memory usage pattern. Choosing 16-bit data types can help reduce the register and memory footprint and in some cases it can result in better utilization of the ALU parallelism in Apple Family 9 GPUs. For ray tracing shaders too, it is important to reduce shader execution time and improve resource utilization in order to improve the performance.

To render with Metal ray tracing, the first step is to define your scene geometry and build an acceleration structure to allow efficient intersection.

Intersection is performed from a GPU function that creates a ray. This GPU function makes an intersector object to perform intersection. The result returned from intersection will have all the information you may need to either shade the pixel or process it further.

The intersector component of this process is hardware accelerated on Apple Family 9 GPUs.

The hardware intersector is responsible for traversing the acceleration structure, invoking intersection functions and updating the state of the traversal based upon the result of intersection. The intersector is the fundamental API for Metal ray tracing. Using intersection functions, ray payload, intersection tags and the intersection in optimal way can improve the ray tracing performance.

Custom intersection functions are a powerful way to define how rays hit surfaces, but use custom intersection functions only when necessary.

Custom intersection functions are important for implementing features like alpha testing. Alpha testing is used to add more geometric detail to the scene, like in the chains and leaves from this image. Alpha testing is implemented by using a custom intersection function.

The logic inside custom intersection functions is responsible for accepting or rejecting intersections as the ray traverses the acceleration structure.

In this case, the custom intersection function logic will reject the first intersection, but it will accept the second intersection since an opaque surface has been intersected.

Custom intersection functions can enable additional logic to be executed on the shader course. Use it only when necessary. The opaque triangle intersectors are the fastest path.

If you need custom intersection functions, note that the hardware will be sorting and grouping by intersection function. Having a lot of intersection functions will make it harder to find matches and group, so avoid duplicate intersection functions to help in grouping optimally.

And take advantage of the Metal intersection function table indexing mechanism to create simple tables with one entry per function.

To run the intersection test, the hardware intersection creates SIMDgroup for multiple rays and then each ray is tested against multiple primitives in parallel.

Since the custom intersection functions are running in parallel, they will need to be serialized if they perform any operation that has side effects. This includes memory writes to the payload or other device memory. Similarly, any operations that introduce divergence such as indirect function calls will also reduce the parallelism of the intersection function execution. It's best to perform these operations as late as possible in the intersection function to allow maximum parallelism until that point.

In this example, ray payload is updated first and then some work unrelated to the payload update is performed.

This will cause all the code after payload update to be run serially. Instead, you can modify the intersection function to have all the work unrelated to the payload update to be done first and then update the payload. This will maximize the intersection function parallelism.

Returning to the hardware intersector model, this flow chart explains the process, but it is overlooking one vital element.

During intersection, ray trace scratch space is used to store the state of the traversal and return results to the GPU function calling intersect.

The intersector API supports a payload for each ray. The larger the payload structure is the more impact it will have on ray tracing performance.

When it comes to ray payload, the intersection result may have most of the data you need and it is best to avoid using any ray payload. If you need a payload, avoid a global uber payload structure. Instead, specialize the structure for each intersect call.

Minimize the size of the structure with packed data types and remove any fields that are not needed. Optimizing ray payload usage will result in more rays being processed. For example, consider a basic payload with the intersection position, a flag to indicate a hit, and a color. In memory, the fields would be laid out like this.

The position member would be at the start and due to its size and alignment, the hit flag would be 16 bytes from the start, but then the RGB member is at a byte offset of 32, making an overall struct size of 48 bytes.

By changing the flow three values to their packed equivalence, there is less space lost to alignment. The hit flag can be removed since it is not needed when using the Metal ray tracing API, you can just check the type of intersection in the intersection result. This is easy to use and more performant, especially for visibility rays like shadows and occlusion. Similarly, the position can be computer-based on the ray's origin, direction and the intersection distance from the result.

And then to reduce the size further, the RGB color can be packed to four bytes in the intersection function using the packing methods in Metal shading language.

In this example, ray data payload structure started off with the size of 48 bytes and reduced to four bytes. By using such methods, you can optimize your array payload to improve the rate tracing performance.

Like ray payload, intersection tags also affect ray tracing performance in a similar way.

Another contributor to ray tracing scratch usage is the intersection tags on the intersector. These tags are the additional state for the traversal to track. The world space data tag in this declaration means that the object to world and world to object matrices have to be stored for each ray. This adds to the retracing scratch usage and will impact occupancy during the intersect call.

The other important thing to note with the tags is that they need to match between the intersector and the intersection functions that it calls.

Intersector is better than intersection query because of how the intersection query API impacts the ray tracing performance.

Looking at the hardware intersector model, it is a great fit for the intersector in the shading language. An intersection query defines an object that does not use custom intersection functions. The intersection code is executed in the original GPU function and the hardware intersector needs to wait until the code completes before continuing the traversal.

If you choose to use intersection query, the hardware has no custom intersection functions to sort and cannot group the execution. It also needs to use more ray tracing scratch memory to allow it to return to the GPU function.

Intersection query is the alternative model for ray intersection to support portability from other shading languages. Since intersector aligns with the hardware implementation, prefer intersector over intersection query.

If you do need to use intersection query, use as few query objects as possible. If multiple intersection queries are necessary, try to reuse the query object, but change the properties. This enables reuse of the ray tracing scratch for one query. For example, if you have an intersection query object IQ1 for doing some ray tracing work, and then if you need to do more ray tracing work with the opaque opacity set, then instead of creating new intersection query object, simply use the intersection params to reset the existing intersection query object with opaque opacity.

This way you can reuse the ray tracing scratch memory.

When using multiple intersection queries, avoid switching between them and overlapping their traversal. This avoids expensive swaps between the in-progress hardware traversals.

For example, in your ray tracing work, instead of switching from IQ1 to IQ2 and then back to IQ1. Continue with IQ1 and complete the ray tracing work with it before switching to IQ2. To summarize ray tracing best practices, use custom intersection function only when necessary. Optimize ray payload.

Minimize the number of intersection tags.

Use intersector over intersection query. To learn more about ray tracing with Metal, please watch, "Your guide to Metal ray tracing." And to learn how to use new ray tracing counters from Metal debugger in Xcode, check out, "Discover new Metal profiling tools for M3 and A17 Pro." To recap, in order to improve performance of your Metal shaders, you can reduce shader execution time by using Metal features like function constants and function groups. Using such features can enable more optimization opportunities in Metal, improve thread occupancy with better resource utilization to increase parallelism.

Apply the best practices for intersection function, ray payload, intersection tags, and the intersector to make the best use of the hardware accelerated ray tracing. Thank you very much.
"""


```

## Examples/SwiftAnthropicExample/SwiftAnthropicExample/OptionsListView.swift
```swift
//
//  OptionsListView.swift
//  SwiftAnthropicExample
//
//  Created by James Rochabrun on 2/24/24.
//

import Foundation
import SwiftAnthropic
import SwiftUI

struct OptionsListView: View {
   
   let service: AnthropicService
   
   @State private var selection: APIOption? = nil
   
   /// https://docs.anthropic.com/claude/reference/getting-started-with-the-api
   enum APIOption: String, CaseIterable, Identifiable {
      
      case message = "Message"
      case messageFunctionCall = "Function Call"
      case thinking = "Thinking Mode"

      var id: Self { self }
   }

   var body: some View {
      List(APIOption.allCases, id: \.self, selection: $selection) { option in
         Text(option.rawValue)
      }
      .sheet(item: $selection) { selection in
         VStack {
            Text(selection.rawValue)
               .font(.largeTitle)
               .padding()
            switch selection {
            case .message:
               MessageDemoView(observable: .init(service: service))
            case .messageFunctionCall:
               MessageFunctionCallingDemoView(observable: .init(service: service))
            case .thinking:
               ThinkingModeMessageDemoView(observable: .init(service: service))
                                           
            }
         }
      }
   }
}
```

## Examples/SwiftAnthropicExample/SwiftAnthropicExample/PhotoPicker.swift
```swift
//
//  PhotoPicker.swift
//  SwiftAnthropicExample
//
//  Created by James Rochabrun on 3/4/24.
//

import PhotosUI
import SwiftUI

// MARK: PhotoPicker

struct PhotoPicker: View {
   
   @State private var selectedItems: [PhotosPickerItem] = []
   @Binding private var selectedImageURLS: [URL]
   @Binding private var selectedImages: [Image]
   
   init(
      selectedImageURLS: Binding<[URL]>,
      selectedImages: Binding<[Image]>)
   {
      _selectedImageURLS = selectedImageURLS
      _selectedImages = selectedImages
   }
   
   var body: some View {
      PhotosPicker(selection: $selectedItems, matching: .images) {
         Image(systemName: "photo")
      }
      .onChange(of: selectedItems) {
         Task {
            selectedImages.removeAll()
            for item in selectedItems {
               if let data = try? await item.loadTransferable(type: Data.self) {
                  let base64String = data.base64EncodedString()
                  let url = URL(string: "data:image/jpeg;base64,\(base64String)")!
                  selectedImageURLS.append(url)
                  #if canImport(UIKit)
                  if let uiImage = UIImage(data: data) {
                     let image = Image(uiImage: uiImage)
                     selectedImages.append(image)
                  }
                  #elseif canImport(AppKit)
                  if let uiImage = NSImage(data: data) {
                     let image = Image(nsImage: uiImage)
                     selectedImages.append(image)
                  }
                  #endif

               }
            }
         }
      }
   }
}

#Preview {
   PhotoPicker(selectedImageURLS: .constant([]), selectedImages: .constant([Image(systemName: "photo")]))
}
```

## Examples/SwiftAnthropicExample/SwiftAnthropicExample/ServiceSelectionView.swift
```swift
//
//  ServiceSelectionView.swift
//  SwiftAnthropicExample
//
//  Created by Lou Zell on 7/31/24.
//

import SwiftUI

struct ServiceSelectionView: View {

   var body: some View {
      NavigationStack {
         List {
            Section("Select Service") {
               NavigationLink(destination: ApiKeyIntroView()) {
                  VStack(alignment: .leading) {
                     Text("Default Anthropic Service")
                        .padding(.bottom, 10)
                     Group {
                        Text("Use this service to test Anthropic functionality by providing your own Anthropic key.")
                     }
                     .font(.caption)
                     .fontWeight(.light)
                  }
               }

               NavigationLink(destination: AIProxyIntroView()) {
                  VStack(alignment: .leading) {
                     Text("AIProxy Service")
                        .padding(.bottom, 10)
                     Group {
                        Text("Use this service to test Anthropic functionality with requests proxied through AIProxy for key protection.")
                     }
                     .font(.caption)
                     .fontWeight(.light)
                  }
               }
            }
         }
      }
   }
}

#Preview {
   ServiceSelectionView()
}
```

## Examples/SwiftAnthropicExample/SwiftAnthropicExample/SwiftAnthropicExampleApp.swift
```swift
//
//  SwiftAnthropicExampleApp.swift
//  SwiftAnthropicExample
//
//  Created by James Rochabrun on 2/24/24.
//

import SwiftUI

@main
struct SwiftAnthropicExampleApp: App {
    var body: some Scene {
        WindowGroup {
           ServiceSelectionView()
        }
    }
}
```

## Examples/SwiftAnthropicExample/SwiftAnthropicExample/Thinking/ThinkingModeMessageDemoObservable.swift
```swift
//
//  ThinkingModeMessageDemoObservable.swift
//  SwiftAnthropic
//
//  Created by James Rochabrun on 2/24/25.
//

import Foundation
import SwiftAnthropic
import SwiftUI

@MainActor
@Observable class ThinkingModeMessageDemoObservable {
   
   let service: AnthropicService
   var message: String = ""
   var thinkingContentMessage = ""
   var errorMessage: String = ""
   var isLoading = false
   var inputTokensCount: String?
   
   // State for managing conversation
   private var messages: [MessageParameter.Message] = []
   
   // Handler for processing thinking content
   private var streamHandler = StreamHandler()
   
   init(service: AnthropicService) {
      self.service = service
   }
   
   // Send a message to Claude with thinking enabled
   func sendMessage(prompt: String, budgetTokens: Int = 16000) async throws {
      guard !prompt.isEmpty else {
         errorMessage = "Please enter a prompt"
         return
      }
      
      // Reset state for new response
      message = ""
      thinkingContentMessage = ""
      errorMessage = ""
      streamHandler.reset() // Clear previous stream data
      
      // Add user message to conversation
      let userMessage = MessageParameter.Message(
         role: .user,
         content: .text(prompt)
      )
      messages.append(userMessage)
      
      // Create parameters with thinking enabled
      let parameters = MessageParameter(
         model: .claude37Sonnet,
         messages: messages,
         maxTokens: 20000,
         stream: true,
         thinking: .init(budgetTokens: budgetTokens)
      )
      
      // Count tokens (optional)
      let tokenCountParams = MessageTokenCountParameter(
         model: .claude37Sonnet,
         messages: messages
      )
      
      do {
         // Get token count
         let tokenCount = try await service.countTokens(parameter: tokenCountParams)
         inputTokensCount = "\(tokenCount.inputTokens)"
         
         // Stream the response
         isLoading = true
         let stream = try await service.streamMessage(parameters)
         
         // Process stream events
         for try await result in stream {
            // Use the ThinkingStreamHandler to process events
            streamHandler.handleStreamEvent(result)
            
            // Update UI elements based on event type
            updateUIFromStreamEvent(result)
         }
         
         // Once streaming is complete, store assistant's response in conversation history
         let finalMessage = streamHandler.textResponse
         if !finalMessage.isEmpty {
            // Get thinking blocks from the handler
            let thinkingBlocks = streamHandler.getThinkingBlocksForAPI()
            
            // Create content objects: thinking blocks + text
            var contentObjects = thinkingBlocks
            contentObjects.append(.text(finalMessage))
            
            // Create assistant message with both thinking blocks and text
            let assistantMessage = MessageParameter.Message(
               role: .assistant,
               content: .list(contentObjects)
            )
            
            // Add to conversation history
            messages.append(assistantMessage)
            message = finalMessage // Update UI
         }
         
         isLoading = false
      } catch {
         isLoading = false
         errorMessage = "Error: \(error.localizedDescription)"
      }
   }
   
   // Just update UI elements based on stream events, no need to track state
   private func updateUIFromStreamEvent(_ event: MessageStreamResponse) {
      // Update UI elements based on deltas
      if let delta = event.delta {
         switch delta.type {
         case "thinking_delta":
            if let thinking = delta.thinking {
               // Update the thinking content shown in UI
               thinkingContentMessage += thinking
            }
         case "text_delta":
            if let text = delta.text {
               // Update the message shown in UI
               message += text
            }
         default:
            break
         }
      }
   }
   
   func clearConversation() {
      message = ""
      thinkingContentMessage = ""
      errorMessage = ""
      messages.removeAll()
      inputTokensCount = nil
      streamHandler.reset()
   }
}
```

## Examples/SwiftAnthropicExample/SwiftAnthropicExample/Thinking/ThinkingModeMessageDemoView.swift
```swift
//
//  ThinkingModeMessageDemoView.swift
//  SwiftAnthropic
//
//  Created by James Rochabrun on 2/24/25.
//

import SwiftUI
import SwiftAnthropic

@MainActor
struct ThinkingModeMessageDemoView: View {
   
   let observable: ThinkingModeMessageDemoObservable
   @State private var prompt: String = ""
   @State private var thinkingBudget: Double = 16.0
   @State private var showThinking: Bool = true
   
   var body: some View {
      VStack {
         // Header with token count
         HStack {
            Text("Claude 3.7 with Extended Thinking")
               .font(.headline)
            Spacer()
            if let inputTokensCount = observable.inputTokensCount {
               Text("Tokens: \(inputTokensCount)")
                  .font(.caption)
                  .foregroundColor(.secondary)
            }
         }
         .padding()
         
         // Thinking budget slider
         VStack(alignment: .leading) {
            Text("Thinking Budget: \(Int(thinkingBudget * 1000)) tokens")
               .font(.caption)
            Slider(value: $thinkingBudget, in: 1...32)
         }
         .padding(.horizontal)
         
         // Show/hide thinking toggle
         Toggle("Show Thinking Process", isOn: $showThinking)
            .padding(.horizontal)
         
         // Error message
         if !observable.errorMessage.isEmpty {
            Text(observable.errorMessage)
               .foregroundColor(.red)
               .padding()
         }
         
         // Main content area (scrollable)
         ScrollView {
            VStack(alignment: .leading, spacing: 16) {
               // Thinking content (only shown if toggle is on)
               if showThinking && !observable.thinkingContentMessage.isEmpty {
                  VStack(alignment: .leading) {
                     Text("Claude's Thinking:")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                     
                     Text(observable.thinkingContentMessage)
                        .foregroundColor(.blue.opacity(0.8))
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                  }
                  .padding(.horizontal)
               }
               
               // Model's response
               if !observable.message.isEmpty {
                  VStack(alignment: .leading) {
                     Text("Claude's Response:")
                        .font(.subheadline)
                        .fontWeight(.bold)
                     
                     Text(observable.message)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                  }
                  .padding(.horizontal)
               }
            }
            .padding(.bottom, 100) // Extra padding for input area
         }
         
         Spacer()
         
         // Input area (fixed at bottom)
         VStack {
            HStack {
               Button("Clear Conversation") {
                  observable.clearConversation()
                  prompt = ""
               }
               .buttonStyle(.bordered)
               
               Spacer()
            }
            .padding(.horizontal)
            
            HStack {
               TextField("Enter your message...", text: $prompt, axis: .vertical)
                  .textFieldStyle(.roundedBorder)
                  .lineLimit(1...5)
               
               Button {
                  Task {
                     try await observable.sendMessage(
                        prompt: prompt,
                        budgetTokens: Int(thinkingBudget * 1000)
                     )
                     prompt = ""
                  }
               } label: {
                  Image(systemName: "paperplane.fill")
                     .foregroundColor(.blue)
               }
               .disabled(prompt.isEmpty || observable.isLoading)
            }
            .padding()
         }
         .background(Color(UIColor.systemBackground))
      }
      .overlay(
         Group {
            if observable.isLoading {
               VStack {
                  ProgressView()
                     .scaleEffect(1.5)
                  Text("Claude is thinking...")
                     .padding(.top)
               }
               .padding()
               .background(Color(UIColor.systemBackground).opacity(0.8))
               .cornerRadius(10)
               .shadow(radius: 10)
            }
         }
      )
   }
}
```

## Examples/SwiftAnthropicExample/SwiftAnthropicExampleTests/SwiftAnthropicExampleTests.swift
```swift
//
//  SwiftAnthropicExampleTests.swift
//  SwiftAnthropicExampleTests
//
//  Created by James Rochabrun on 2/24/24.
//

import XCTest
@testable import SwiftAnthropicExample

final class SwiftAnthropicExampleTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
```

## Examples/SwiftAnthropicExample/SwiftAnthropicExampleUITests/SwiftAnthropicExampleUITests.swift
```swift
//
//  SwiftAnthropicExampleUITests.swift
//  SwiftAnthropicExampleUITests
//
//  Created by James Rochabrun on 2/24/24.
//

import XCTest

final class SwiftAnthropicExampleUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
```

## Examples/SwiftAnthropicExample/SwiftAnthropicExampleUITests/SwiftAnthropicExampleUITestsLaunchTests.swift
```swift
//
//  SwiftAnthropicExampleUITestsLaunchTests.swift
//  SwiftAnthropicExampleUITests
//
//  Created by James Rochabrun on 2/24/24.
//

import XCTest

final class SwiftAnthropicExampleUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
```

