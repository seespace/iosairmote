# iOS Airmote #

Remote Control Application for InAir system (iOS)

### How to build? ###

* Make sure you have [CocoaPods](http://cocoapods.org) installed. `sudo gem install cocoapods`
* Download source code. `git clone git@bitbucket.org:seespace/iosairmote.git`
* Go to the source code folder, install required pods. `cd iosairmote && pod install`
* Open `Airmote+.xcworkspace`
* Build!

### How to run? ###

Note: Since Android Emulator maintains a virtual ethernet LAN, sending events from device to emulator is not possible unless you have a [modified adb](http://rxwen.blogspot.com/2009/11/adb-for-remote-connections.html).

* Start InAir emulator and open an InAir application.
* You need to forward port **8989** on the emulator to same port on the host machine: `adb forward tcp:8989 tcp:8989`
* Run the iOS Airmote app on iOS Simulator, enter `127.0.0.1` as AirServer IP address.

### Supports ###
* Bug reporting: file an issue in this repo
* Discussions/questions: create new topic at [InAir Developer Forums](http://developer.inair.tv/category/13/remote-control-applications-forum)

### License ###

The MIT License

Copyright (c) 2014, SeeSpace. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.