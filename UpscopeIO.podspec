#
# Be sure to run `pod lib lint UpscopeIO.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'UpscopeIO'
  s.version          = '2025.1.0'
  s.summary          = 'UpscopeIO is a library for a comfort screen sharing.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
'UpscopeIO is iOS SDK to integrate screen sharing into your apps.'
                       DESC

  s.homepage         = 'https://cobrowsingapi.com/'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Upscope' => 'team@upscope.com' }
  s.source           = { :git => 'https://github.com/upscopeio/cobrowsing-sdk-ios', :tag => s.version.to_s }
  s.social_media_url = 'https://x.com/upscope'

  s.ios.deployment_target = '16.0'
  s.swift_version = '5.0'
  s.platforms = {
      "ios": "16.0"
  }

  s.source_files = 'Sources/**/*'
  
  # s.resource_bundles = {
  #   'UpscopeIO' => ['UpscopeIO/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
