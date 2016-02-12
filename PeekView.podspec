Pod::Spec.new do |s|

  s.name         = "PeekView"
  s.version      = "1.0.1"
  s.summary      = "PeekView supports peek, pop and preview actions for iOS devices without 3D Touch capibility"

  s.description  = "When implementing peek, pop and preview actions with 3D Touch, you may want to support such features for users accessing your app from older devices that don't provide 3D Touch capibility. PeekView hence can be used as an alternative in such case."

  s.homepage     = "https://github.com/itsmeichigo/PeekView"
  s.screenshots  = "https://github.com/itsmeichigo/PeekView/raw/master/peekview.gif", "https://github.com/itsmeichigo/PeekView/raw/master/screenshot.png"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Huong Do" => "huongdt29@gmail.com" }
  s.social_media_url   = "http://twitter.com/itsmeichigo"

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/itsmeichigo/PeekView.git", :tag => "1.0" }

  s.source_files  = "Source"

  s.resources = "Source/Assets/*.png"
  s.ios.resource_bundle = { 'PeekView' => 'Pod/Assets/*.png' }


end
