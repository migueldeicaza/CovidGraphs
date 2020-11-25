## Getting Started Guide

1. Fork the repo and open CovidGraphs.xcodeproj in Xcode
2. Open the "Project navigator" view in the side pane as you can see below, and select the top most element, the "CovidGraphs" project. And then for each of the 5 Targets, change the Team to your personal team, and the 3rd segment of the Bundle identifier to something unique (I changed CovidGraphs to CovidGras):
<img width="869" alt="Project Targets in Xcode" src="https://user-images.githubusercontent.com/8262287/100170188-19a13e80-2e93-11eb-8fdc-797c6ce07acd.png">

3. Then expand the WatchApp directory, and in the info.plist, change the WKCompanionAppBundleIdentifier in the same way as shown above:
<img width="820" alt="WKCompanionAppBundleIdentifier in WatchApp's info.plist" src="https://user-images.githubusercontent.com/8262287/100170192-1c039880-2e93-11eb-8e61-3d779f6ca848.png">

4. Then expand the WatchApp Extension directory, and in the info.plist, change the WKAppBundleIdentifier in the same way as shown in step 2:
<img width="765" alt="WKAppBundleIdentifier in WatchApp Extension's info.plist" src="https://user-images.githubusercontent.com/8262287/100170194-1c9c2f00-2e93-11eb-9f2a-d91055195501.png">

5. Connect your phone to your Mac and press the play button to get it installed.

Note: You might have to go into your Settings-> Device Management-> Select the certificate and verify/install
![Screenshot showing Device Management in Settings](https://user-images.githubusercontent.com/8262287/100170897-9a146f00-2e94-11eb-86b5-460700f260a8.PNG)

### Getting Involved

Feel free to open issues and submit pull requests with enhancements