#
# Be sure to run `pod lib lint IosUtils.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'IosUtils'
  s.version          = '0.0.1'
  s.summary          = 'iOS Utils'

  s.homepage         = "https://github.com/woko666/IosUtils"
  s.author           = { 'Woko' => 'woko@centrum.cz' }
  s.source           = { :git => "https://github.com/woko666/IosUtils.git" }

  s.ios.deployment_target = '11.0'

  s.source_files  = ["IosUtils/**/*.swift"]
  s.library = 'iconv'
  s.dependency 'SQLite.swift', '~> 0.11.5'
end
