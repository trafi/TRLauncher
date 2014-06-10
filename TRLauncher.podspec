Pod::Spec.new do |s|
  s.name         = "TRLauncher"
  s.version      = "0.9"
  s.summary      = "TRLauncher"
  s.homepage     = "https://github.com/trafi/TRLauncher/"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = 'Trafi'
  s.platform     = :ios
  s.source       = { :git => "https://github.com/trafi/TRLauncher.git", :tag => s.version.to_s }
  s.source_files = 'TRLauncher'
  s.requires_arc = true
end