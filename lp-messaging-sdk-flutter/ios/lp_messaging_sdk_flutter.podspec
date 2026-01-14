Pod::Spec.new do |s|
  s.name             = 'lp_messaging_sdk_flutter'
  s.version          = '0.1.0'
  s.summary          = 'Flutter plugin wrapping LivePerson iOS Messaging SDK.'
  s.description      = <<-DESC
                        Flutter plugin that presents the native LivePerson conversation view.
                       DESC
  s.homepage         = 'https://liveperson.example.com'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Liveperson' => 'dev@liveperson.example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency       'Flutter'
  s.dependency       'LPMessagingSDK', '6.25.0'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
end
