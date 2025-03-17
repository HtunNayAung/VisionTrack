# Navigation Assistant iOS App

An iOS application that provides navigation assistance with voice control capabilities, built using SwiftUI and Google Maps SDK.

## Features

- Voice control navigation

- Speech-to-text input for destinations

- Text-to-speech feedback

- Gesture-based voice mode activation

## Prerequisites

- Xcode 14.0 or later

- iOS 15.0 or later

- CocoaPods package manager

- Google Maps API Key

- Swift 5.0 or later

## Dependencies

- SwiftUI

- GoogleMaps

- AVFoundation

- Speech

## Installation

1. Clone the repository

```bash

git  clone  https://github.com/HtunNayAung/VisionTrack.git

```

2. Install CocoaPods dependencies

```bash

cd  Demo

pod  install

```

3. Open the workspace in Xcode

```bash

open  Demo.xcworkspace

```

4. Configure the Google Maps API Key

- Obtain a Google Maps API Key from the Google Cloud Console.

- Add the key to GMSAPIKey in info.plist

## Required Permissions

Add the following to Info.plist:

- Privacy - Speech Recognition Usage Description

- Privacy - Microphone Usage Description

- Privacy - Location When In Use Usage Description

- Privacy - Location Always and When In Use Usage Description
