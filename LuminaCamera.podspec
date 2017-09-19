Pod::Spec.new do |s|
  s.name        = "LuminaCamera"
  s.version     = "v0.5.1"
  s.summary     = "Lumina gives you a camera for most photo processing needs, including streaming frames for CoreML live detection."
  s.homepage    = "https://github.com/dokun1/Lumina"
  s.license     = { :type => "MIT" }
  s.authors     = { "dokun1" => "david@okun.io" }

  s.requires_arc = true
  s.ios.deployment_target = "10.0"
  s.source   = { :git => "https://github.com/dokun1/Lumina.git", :tag => s.version }
  s.source_files = "Lumina/Lumina/*.swift"
end
