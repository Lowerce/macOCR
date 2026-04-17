platform :osx, '10.13'

target 'ocr' do
  pod 'ScreenCapture'
  pod 'ArgumentParserKit'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.13'
    end
  end
end
