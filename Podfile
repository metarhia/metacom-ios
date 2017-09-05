# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

abstract_target 'Devices' do
	
	use_frameworks!
	
	# Pods for MetaCom-iOS
	pod 'JSQMessagesViewController'
	pod 'ReachabilitySwift'
	
	target 'MetaCom-iOS-Device' do
	end
	
	target 'MetaCom-iOS-Simulator' do
	end
	
end

post_install do |installer|
	Dir.glob(installer.sandbox.target_support_files_root + "Pods-*/*.sh").each do |script|
		flag_name = File.basename(script, ".sh") + "-Installation-Flag"
		folder = "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
		file = File.join(folder, flag_name)
		content = File.read(script)
		content.gsub!(/set -e/, "set -e\nKG_FILE=\"#{file}\"\nif [ -f \"$KG_FILE\" ]; then exit 0; fi\nmkdir -p \"#{folder}\"\ntouch \"$KG_FILE\"")
		File.write(script, content)
	end
	
	installer.pods_project.targets.each do |target|
		target.build_configurations.each do |config|
			cflags = config.build_settings['OTHER_CFLAGS'] || ['$(inherited)']
			cflags << '-fembed-bitcode'
			config.build_settings['OTHER_CFLAGS'] = cflags
		end
	end
end
