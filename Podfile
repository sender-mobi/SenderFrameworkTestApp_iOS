# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

use_frameworks!
workspace 'SenderFrameworkTest.xcworkspace'

def sender_pods
  pod 'libPhoneNumber-iOS', '0.9.10'
  pod 'KAProgressLabel', '2.1'
  pod 'StaticDataTableViewController', '2.0.5'
  pod 'SAMKeychain', '1.5.2'
  pod 'SDWebImage', '4.1.0'
  pod 'mp3lame-for-ios','0.1.1'
  pod 'GoogleSignIn', '4.0.2'
  pod 'ObjectiveLuhn', '1.0.2'
end

target 'SenderFrameworkTest' do
  project 'SenderFrameworkTest.xcodeproj'
  sender_pods
end

target 'SenderFramework' do
    project 'SenderFramework/SENDER/SENDER.xcodeproj'
    sender_pods
end