
Pod::Spec.new do |s|
  s.name             = "MRLocalNotificationFacade"
  s.version          = "2.0.0"
  s.summary          = "MRLocalNotificationFacade is a class that wraps most of the APIs required for dealing with local notifications in iOS."
  s.homepage         = "https://github.com/hectr/MRLocalNotificationFacade"
  s.screenshots      = "https://github.com/hectr/MRLocalNotificationFacade/blob/master/notification.jpg?raw=true"
  s.license          = 'MIT'
  s.author           = { "hectr" => "h@mrhector.me" }
  s.source           = { :git => "https://github.com/hectr/MRLocalNotificationFacade.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/hectormarquesra'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'MRLocalNotificationFacade'

  s.frameworks = 'UIKit'
end
