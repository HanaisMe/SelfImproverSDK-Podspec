Pod::Spec.new do |s|
  s.name             = 'SelfImproverSDK'
  s.version          = '0.1.2'
  s.summary          = 'Link your app with the app, Self Improver'

  s.description      = <<-DESC
    'Self Improver' is an app that encourages a user to regularly check their own goals.
  DESC

  s.homepage         = 'https://github.com/HanaisMe/SelfImproverSDK-Podspec'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'HanaIsMe' => 'hanaismelee@gmail.com' }
  s.source           = { :git => 'https://github.com/HanaisMe/SelfImproverSDK.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/jeongsik_lee'

  s.ios.deployment_target = '11.0'

  s.source_files = 'Source/Classes/**/*.{swift}'
  s.swift_version = '4.2'

  s.frameworks = 'UIKit'
end
