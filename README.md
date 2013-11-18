# Foursquare API v2 for iOS

A simple Objective-C wrapper for the foursquare API v2. It allows you to integrate foursquare into your iOS application.

## Features

* Simple, small and easy to use
* Authentication using Safari (see Future Plans below)
* Asynchronous requests support
* Open source BSD license

## Requirements

* Xcode 5 or later
* Base SDK: iOS 7.0 or later
* Deployment Target: iOS 5.0 or later

This library requires your app to link against the following frameworks:

* Foundation.framework
* MobileCoreServices.framework
* UIKit.framework

## Getting Started

1. ### [Register](https://foursquare.com/oauth/) for an API consumer key

	In order to obtain an oAuth access token, this library uses Safari and a custom URL scheme that brings the user back to your app. For example, FSQDemo app uses the `fsqdemo` URL scheme.

	![FSQ Demo](https://github.com/baztokyo/foursquare-ios-api/raw/master/images/fsq_demo.png "FSQ Demo")

	The client ID and callback URL are required when creating the BZFoursquare object.

		BZFoursquare *foursquare = [[BZFoursquare alloc] initWithClientID:@"YOUR_CLIENT_ID" callbackURL:@"YOUR_CALLBACK_URL"];

2. ### Installation

	Copy all the files from the BZFoursquare folder to your project.

	#### Automatic Reference Counting (ARC)

	If you are including this library in your project that uses Objective-C Automatic Reference Counting (ARC) enabled, you will need to set the `-fno-objc-arc` compiler flag on all of the BZFoursquare source files. To do this in Xcode, go to your active target and select the "Build Phases" tab. In the "Compiler Flags" column, set `-fno-objc-arc` for each of the BZFoursquare source files. The following is the setting of the FSQDemo project.

	![Compile Sources](https://github.com/baztokyo/foursquare-ios-api/raw/master/images/compile_sources.png "Compile Sources")

	#### MobileCoreServices

	You will need to add the MobileCoreServices library to your project. To do this in Xcode, go to your active target and select the "Build Phases" tab. In the "Link Binary with Libraries" section, click the plus button and select MobileCoreServices from the dialog box that is presented.

	![Mobile Core Services](https://github.com/baztokyo/foursquare-ios-api/raw/master/images/mobilecoreservices.png "Mobile Core Services")

3. ### Set up your custom URL scheme

	Add your custom URL scheme to your project. The following is the setting of the FSQDemo project.

	![URL Types](https://github.com/baztokyo/foursquare-ios-api/raw/master/images/url_types.png "URL Types")

## Sample Applications

This library comes with FSQDemo app that demonstrates authorization, making API calls to guide you in development.

To build and run FSQDemo app, open the FSQDemo project with Xcode 5 or later and set `FOURSQURE_CLIENT_ID` to your client ID.

![FOURSQURE\_CLIENT\_ID](https://github.com/baztokyo/foursquare-ios-api/raw/master/images/foursquare_client_id.png "FOURSQURE_CLIENT_ID")

## License

Foursquare API v2 for iOS is available under the 2-clause BSD license. See the LICENSE file for more info.

## Future Plans

* Foursquare native authentication support
