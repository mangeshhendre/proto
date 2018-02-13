#/bin/bash
if [ "$IOS_PD_DIR" = "" ]; then
   echo "Please set \$IOS_PD_DIR to the root iOS PhotoDirect base directory"
   exit -1
fi

if [ ! -d $IOS_PD_DIR ]; then
    echo "Invalid \$IOS_PD_DIR: $IOS_PD_DIR"
    exit -2
fi

mkdir -p $IOS_PD_DIR/pd_grpc

# Base objects
protoc --objc_out=$IOS_PD_DIR/pd_grpc sgt/content.proto

# Services
protoc --objcgrpc_out=$IOS_PD_DIR/pd_grpc --objc_out=$IOS_PD_DIR/pd_grpc services/mediasvc.proto


# Podfiles

cat > $IOS_PD_DIR/Podfile <<EOF
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

install! 'cocoapods', :deterministic_uuids => false

target 'PhotoDirect' do
  pod 'PhotoDirect-gRPC', :path => '.', :configurations => ['Debug', 'Release']  
   target 'PhotoDirectTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'PhotoDirect-gRPC', :path => '.'
  end
end

post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
          config.build_settings['ENABLE_BITCODE'] = 'NO'
        end
    end
end

EOF

cat > $IOS_PD_DIR/PhotoDirect-gRPC.podspec <<EOF
Pod::Spec.new do |s|
  s.name     = "PhotoDirect-gRPC"
  s.version  = "0.0.1"
  s.license  = "proprietary"
  s.authors  = { 'gRPC contributors' => 'grpc-io@googlegroups.com' }
  s.homepage = "https://safeguardproperties.com/"
  s.summary = "PhotoDirect gRPC"
  s.source = { :git => '' }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"

  # Base directory where the .proto files are.
  
  # Run protoc with the Objective-C and gRPC plugins to generate protocol messages and gRPC clients.
  s.dependency "!ProtoCompiler-gRPCPlugin", "~> 1.0"

  # Pods directory corresponding to this app's Podfile, relative to the location of this podspec.
  pods_root = 'Pods'

  # Path where Cocoapods downloads protoc and the gRPC plugin.
  protoc_dir = "#{pods_root}/!ProtoCompiler"
  protoc = "#{protoc_dir}/protoc"
  plugin = "#{pods_root}/!ProtoCompiler-gRPCPlugin/grpc_objective_c_plugin"

  # Directory where the generated files will be placed.
  dir = "#{pods_root}/#{s.name}"

  s.prepare_command = <<-CMD
    mkdir -p #{dir}
    cp -r pd_grpc/* #{dir}
  CMD

  # Files generated by protoc
  s.subspec "sgt" do |ms|
    ms.source_files = "#{dir}/*.pbobjc.{h,m}", "#{dir}/**/*pbobjc.{h,m}"
    ms.header_mappings_dir = "#{dir}"
    ms.requires_arc = false
    # The generated files depend on the protobuf runtime.
    ms.dependency "Protobuf"
  end

  # Files generated by the gRPC plugin
  s.subspec "services" do |ss|
    ss.source_files = "#{dir}/*.pbrpc.{h,m}", "#{dir}/**/*.pbrpc.{h,m}"
    ss.header_mappings_dir = "#{dir}"
    ss.compiler_flags = "-I #{dir}"
    ss.requires_arc = true
    # The generated files depend on the gRPC runtime, and on the files generated by protoc.
    ss.dependency "gRPC"
    ss.dependency "gRPC-ProtoRPC"
    ss.dependency "#{s.name}/sgt"
  end

  s.pod_target_xcconfig = {
    # This is needed by all pods that depend on Protobuf:
    'GCC_PREPROCESSOR_DEFINITIONS' => '\$(inherited) GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1',
    # This is needed by all pods that depend on gRPC-RxLibrary:
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
  }
end

EOF
