Pod::Spec.new do |s|
  s.name = 'AlamofireNetworkActivityLogger'
  s.version = '2.3.0'
  s.license = 'MIT'
  s.summary = 'Network request logger for Alamofire'
  s.homepage = 'https://github.com/konkab/AlamofireNetworkActivityLogger'
  s.social_media_url = 'https://www.linkedin.com/in/konstantinkabanov'
  s.authors = { 'Konstantin Kabanov' => 'konstantin@rktstudio.ru' }

  s.source = { :git => 'https://github.com/konkab/AlamofireNetworkActivityLogger.git', :tag => s.version }
  s.source_files = 'Source/*.swift'

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.11'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'

  s.dependency 'Alamofire', '~> 4.6'
end
