# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

workspace 'Marvelous.xcworkspace'

target 'Marvelous' do
  project 'Marvelous/Marvelous.xcodeproj'

  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Marvelous
  pod 'Alamofire', '~> 3.5'
  pod 'SwiftyJSON', '~> 2.4'
  pod 'SDWebImage', '~> 3.8'

  target 'MarvelousTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

target 'MarvelSDK' do
  project 'MarvelSDK/MarvelSDK.xcodeproj'

  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for MarvelSDK

  pod 'Alamofire', '~> 3.5'
  pod 'SwiftyJSON', '~> 2.4'

  target 'MarvelSDKTests' do
    inherit! :search_paths
    # Pods for testing
  end

end