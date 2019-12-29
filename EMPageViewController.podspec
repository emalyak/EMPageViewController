Pod::Spec.new do |s|
  s.name             = "EMPageViewController"
  s.version          = "4.0.0"
  s.summary          = "A better page view controller for iOS."
  s.homepage         = "https://github.com/emalyak/EMPageViewController"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "Erik Malyak" => "erik@maylak.io" }
  s.source           = { :git => "https://github.com/emalyak/EMPageViewController.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/emalyak'
  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.source_files = 'EMPageViewController/*.swift'
  s.swift_version = '4.2'
end
