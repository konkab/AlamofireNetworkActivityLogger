Pod::Spec.new do |s|
  s.name = 'AlamofireNetworkActivityLogger'
  s.version = '3.4.0'
  s.license = 'MIT'
  s.summary = 'Network request logger for Alamofire'
  s.homepage = 'https://github.com/konkab/AlamofireNetworkActivityLogger'
  s.social_media_url = 'https://www.linkedin.com/in/konstantinkabanov'
  s.authors = { 'Konstantin Kabanov' => 'fever9@gmail.com' }

  s.source = { :git => 'https://github.com/konkab/AlamofireNetworkActivityLogger.git', :tag => s.version }
  s.source_files = 'Source/*.swift'
  s.swift_versions = ['5.1', '5.2', '5.3']

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'
  s.tvos.deployment_target = '10.0'
  s.watchos.deployment_target = '3.0'

  s.dependency 'Alamofire', '~> 5.4.0'
end
