#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'fijkplayer'
  s.version          = '0.7.0'
  s.summary          = 'Flutter plugin for ijkplayer'
  s.description      = <<-DESC
Flutter plugin for ijkplayer
                       DESC
  s.homepage         = 'http://github.com/befovy/fijkplayer'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'befovy' => 'befovy@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  s.static_framework = true

  # @ uncomment next 3 lines to debug FIJKPlayer
  # s.preserve_paths = 'Frameworks/*.framework'
  # s.vendored_frameworks = 'Frameworks/IJKPlayer.framework'
  # s.xcconfig = { 'LD_RUNPATH_SEARCH_PATHS' => '"$(PODS_ROOT)/Frameworks/"' }

  s.libraries = "bz2", "z", "stdc++"
  s.dependency 'Flutter'

  # s.use_frameworks!
  s.dependency 'BIJKPlayer', '~> 0.5.1'

  s.ios.deployment_target = '8.0'
end

