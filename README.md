# UpscopeIO

[![Version](https://img.shields.io/cocoapods/v/UpscopeIO.svg?style=flat)](https://cocoapods.org/pods/UpscopeIO)
[![License](https://img.shields.io/cocoapods/l/UpscopeIO.svg?style=flat)](https://cocoapods.org/pods/UpscopeIO)
[![SwiftPM](https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat)](https://swift.org/package-manager/)
[![Platform](https://img.shields.io/cocoapods/p/UpscopeIO.svg?style=flat)](https://cocoapods.org/pods/UpscopeIO)


## Installing Upscope
Upscope supports [Swift Package Manager](https://www.swift.org/package-manager/) and [CocoaPods](https://cocoapods.org/).

### Swift Package Manager

To install Upscope using [Swift Package Manager](https://github.com/swiftlang/swift-package-manager) you can follow the [tutorial published by Apple](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app) using the URL for the Upscope repo with the current version:

1. In Xcode, select “File” → “Add Packages...”
1. Enter https://github.com/upscopeio/cobrowsing-sdk-ios

or you can add the following dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/upscopeio/cobrowsing-sdk-ios", from: "2025.1.0")
```

### CocoaPods
If you do not yet have Podfile, run the command to create it:
```ruby
pod init
```

Add the pod to your Podfile:
```ruby
pod 'UpscopeIO'
```

And then run:
```ruby
pod install
```
After installing the cocoapod into your project and opening .xcworkspace file, import UpscopeIO with
```swift
import UpscopeIO
```

## Getting started...

In order to use UpscopeIO first of all you should initialize a single Upscope manager with your private apiKey:

```swift
let upscopeManager = UpscopeManager(apiKey: myApiKey)
```
Also you can use additional configurations on your choice
```swift
let upscopeManager = UpscopeManager(
    apiKey: <myApiKey>, 
    agentPrompt: ..., 
    identities: ...,
    integrationIds: ...,
    tags: ...,
    uniqueId: ...
)
```
All of these additional properties can be updated in the future if you need this with
```swift
upscopeManager.updateOptions(agentPrompt: .value("Something new!"))
```

Right after this if you have autoConnect option set to true you will be automatically connected to web socket. Otherwise, you need to connect manually: 
```swift
upscopeManager.connect()
```

Methods to subscribe for all events can be used in a such way:
```swift
for event in MessageType.allCases {
    upscopeManager.on(event: event) { [weak self] data in
        // your way to handle the data
    }
}
```

To unsubscribe you can use 'off' method:
```swift
for event in MessageType.allCases {
    upscopeManager.off(event: event)
}
```

## License

UpscopeIO is available under the MIT license. See the LICENSE file for more info.
