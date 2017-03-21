
Pod::Spec.new do |s|
  s.name             = 'RecordVoicePlayer'
  s.version          = '1.0.2'
  s.summary          = 'Record Voice and play the Voice.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/ygqym101620/RecordVoicePlayer.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ygqym101620' => 'yanggq101620@163.com' }
  s.source           = { :git => 'https://github.com/ygqym101620/RecordVoicePlayer.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'RecordVoicePlayer/Classes/**/*'
  
  # s.resource_bundles = {
  #   'RecordVoicePlayer' => ['RecordVoicePlayer/Assets/*.png']
  # }

  s.public_header_files = 'RecordVoicePlayer/Classes/RecordVoicePlayerHeader.h'
  s.frameworks = 'UIKit', 'AVFoundation'
  s.dependency 'AFNetworking', '~> 2.5'
  s.dependency 'ReactiveCocoa', '~>2.5'
end
