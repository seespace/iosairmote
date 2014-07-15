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

* Open InAir emulator and start an InAir application.
* You need to forward port **8989** on the emulator to same port on the host machine: `adb forward tcp:8989 tcp:8989`
* Run the iOS Airmote app on iOS Simulator, enter `127.0.0.1` as AirServer IP address.

### Supports ###
* Bug reporting: file an issue in this repo
* Discussions/questions: create new topic at [InAir Developer Forums](http://developer.inair.tv/category/13/remote-control-applications-forum)