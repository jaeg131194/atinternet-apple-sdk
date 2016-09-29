Pod::Spec.new do |s|
	s.name						      = "ATInternet-SmartSDK"
	s.version					      = '0.9'
	s.summary					      = "AT Internet mobile analytics solution for iOS"
	s.homepage						  = "https://github.com/at-internet/atinternet-ios-swift-sdk"
	s.documentation_url				  = 'http://developers.atinternet-solutions.com/apple-en/getting-started-apple-en/operating-principle-apple-en/'
	s.license					      = "MIT"
	s.author					      = "AT Internet"
	s.platform					      = :ios
    s.ios.deployment_target	          = '8.0'
	s.source					      = { :git => "http://gitblit.intraxiti.com:8090/r/Tag/iOS/Swift/UniversalTracker.git", :branch => 's12_swift3_devices_versions_global'}
	s.source_files = "ATInternetTracker/Sources/*.{h,m,swift}"
	s.resources = "ATInternetTracker/Sources/*.{plist,xcdatamodeld,png,json,mp3,ttf}", "ATInternetTracker/Sources/Images.xcassets", "ATInternetTracker/Sources/ToolbarImages.xcassets"
	s.frameworks		= "CoreData", "CoreFoundation", "UIKit", "CoreTelephony", "SystemConfiguration"
	s.module_name = 'Tracker'
	s.requires_arc = true
	s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.0' }
end
