require 'json'

package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json')))

Pod::Spec.new do |s|
  s.name           = 'ClashKingNative'
  s.version        = package['version']
  s.summary        = package['description']
  s.description    = package['description']
  s.license        = { :type => 'MIT' }
  s.author         = 'ClashKing'
  s.homepage       = 'https://clashk.ing'
  s.platforms      = { :ios => '17.0' }
  s.swift_version  = '5.9'
  s.source         = { :git => 'https://github.com/ClashKingInc/ClashKingApp.git' }
  s.static_framework = true
  s.dependency 'ExpoModulesCore'
  s.source_files = '**/*.{h,m,mm,swift}'
end
