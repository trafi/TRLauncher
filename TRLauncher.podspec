Pod::Spec.new do |s|
  s.name         = "TRLauncher"
  s.version      = "0.9"
  s.summary      = "TRLauncher is a class, that simplifies launch of Trafi application."
  s.homepage     = "https://github.com/trafi/TRLauncher/"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = 'Trafi'
  s.platform     = :ios
  s.ios.deployment_target = '5.0'
  s.source       = { :git => "https://github.com/trafi/TRLauncher.git", :tag => s.version.to_s }
  s.source_files = 'TRLauncher'
  s.requires_arc = true
end