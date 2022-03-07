platform :ios, "13.0"
inhibit_all_warnings!
use_frameworks!

install! 'cocoapods',
            :warn_for_unused_master_specs_repo => false

target 'TideDataMaker' do
	pod 'FMDB'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
      		config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
        end
    end
end



