#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'fijkplayer'
  s.version          = '0.0.1'
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


  # s.frameworks = 'IJKMediaFramework'
  # s.preserve_paths = 'Frameworks/*.framework'
  # s.vendored_frameworks = 'Frameworks/FIJKMediaPlayer.framework'
  # s.resource = 'Frameworks/FIJKMediaPlayer.framework'
  # s.xcconfig = { 'LD_RUNPATH_SEARCH_PATHS' => '"$(PODS_ROOT)/Frameworks/"' }

  s.libraries = "bz2", "z", "stdc++"
  s.dependency 'Flutter'
  s.dependency 'FIJKPlayer'

  s.ios.deployment_target = '8.0'
end

