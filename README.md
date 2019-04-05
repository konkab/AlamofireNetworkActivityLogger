# AlamofireNetworkActivityLogger

[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/AlamofireNetworkActivityLogger.svg)](https://img.shields.io/cocoapods/v/AlamofireNetworkActivityLogger.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/AlamofireNetworkActivityLogger.svg?style=flat)](http://cocoadocs.org/docsets/AlamofireNetworkActivityLogger)

Network activity logger for Alamofire.

## Requirements

- iOS 9.0+ / macOS 10.11+ / tvOS 9.0+ / watchOS 2.0+
- Xcode 8.0+
- Swift 3.2+

## Dependencies

- [Alamofire 4.8+](https://github.com/Alamofire/Alamofire)

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.6.0+ is required.

To integrate AlamofireNetworkActivityLogger into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

pod 'AlamofireNetworkActivityLogger', '~> 2.4'
```

Then, run the following command:

```bash
$ pod install
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate AlamofireNetworkActivityLogger into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "konkab/AlamofireNetworkActivityLogger" ~> 2.4
```

---

## Usage

Import the library:

```swift
import AlamofireNetworkActivityLogger
```

Add the following code to `AppDelegate.swift application:didFinishLaunchingWithOptions:`:

```swift
NetworkActivityLogger.shared.startLogging()
```

Now all NSURLSessionTask objects created by an Alamofire.SessionManager will have their request and response logged to the console, a la:

```
---------------------
GET 'http://example.com/foo/bar.json'
---------------------
200 'http://example.com/foo/bar.json' [0.2535 s]
```

If the default logging level is too verbose—say, if you only want to know when requests fail—then changing it is as simple as:

```swift
NetworkActivityLogger.shared.level = .error
```

## Contact

Konstantin Kabanov

- kabanov_kv@me.com
- Skype: konstantin_kabanov
- [Linkedin](https://ru.linkedin.com/in/konstantinkabanov)

## License

AlamofireNetworkActivityLogger is released under the MIT license. See LICENSE for details.
