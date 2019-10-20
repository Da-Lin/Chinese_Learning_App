# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'CLL' do
  use_frameworks!

  pod 'FlatUIKit'
  pod 'IoniconsKit'
  pod 'IQKeyboardManagerSwift'
  pod 'JVFloatLabeledTextField'
  pod 'NVActivityIndicatorView'
  pod 'Firebase/Core'

  # Crashlytics
  pod 'Fabric', '~> 1.9.0'
  pod 'Crashlytics', '~> 3.12.0'

end


post_install do |installer|
  installer.pods_project.targets.each do |target|
      if ['IoniconsKit'].include? target.name
          target.build_configurations.each do |config|
              config.build_settings['SWIFT_VERSION'] = '4.0'
          end
      end
  end
end
