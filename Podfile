# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Healthy Rush' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  # AUTOMATICALLY MATCH THE DEPLOYMENT TARGET OF ALL THE PODFILES TO THE PROJECT DEPLOYMENT TARGET
  post_install do |installer|
   installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
     config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
     end
    end
   end

  # FOR FIREBASE
  pod 'Firebase/Analytics'
  pod 'Firebase/Auth'
  
  # FOR FACEBOOK
  pod 'FBSDKCoreKit'
  pod 'FBSDKLoginKit'

end
