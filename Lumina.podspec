Pod::Spec.new do |s|
  s.name        = "Lumina"
  s.version     = "1.5.0"
  s.summary     = "Lumina gives you a camera for most photo processing needs, including streaming frames for CoreML live detection."
  s.homepage    = "https://github.com/dokun1/Lumina"
  s.license     = { :type => "MIT" }
  s.authors     = { "dokun1" => "david@okun.io" }

  s.requires_arc = true
  s.ios.deployment_target = "11.0"
  s.source   = { :git => "https://github.com/dokun1/Lumina.git", :tag => s.version }
  s.source_files = ["Lumina/Lumina/Util/Logging/*.swift", "Lumina/Lumina/Util/LuminaLogger.swift", "Lumina/Lumina/Camera/*.swift", "Lumina/Lumina/Camera/Extensions/*.swift", "Lumina/Lumina/Camera/Extensions/Delegates/*.swift", "Lumina/Lumina/Util/Logging/*.swift", "Lumina/Lumina/UI/*.swift", "Lumina/Lumina/UI/Extensions/*.swift", "Lumina/Lumina/UI/Extensions/Delegates/*.swift"]
  s.resource = "Lumina/Lumina/UI/Media.xcassets"
end
