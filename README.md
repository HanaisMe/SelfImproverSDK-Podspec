# Private SDK Development

## Contents

1. Framework
2. Pod Spec
    1. Error Cases
3. Import Pod



# 1. Developing Framework

### SDK itself
1. Xcode File > New > Project > Cocoa Touch Framework
2. Target to create binary for both simulator and device
    1. File > New > Target > Aggregate
    2. Build Phases > New Run Script Phase, copy and paste below

```
set -e

######################
# Options
######################

REVEAL_ARCHIVE_IN_FINDER=true

FRAMEWORK_NAME="${PROJECT_NAME}"

SIMULATOR_LIBRARY_PATH="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${FRAMEWORK_NAME}.framework"

DEVICE_LIBRARY_PATH="${BUILD_DIR}/${CONFIGURATION}-iphoneos/${FRAMEWORK_NAME}.framework"

UNIVERSAL_LIBRARY_DIR="${BUILD_DIR}/${CONFIGURATION}-iphoneuniversal"

FRAMEWORK="${UNIVERSAL_LIBRARY_DIR}/${FRAMEWORK_NAME}.framework"


######################
# Build Frameworks
######################


xcodebuild -project ${PROJECT_FILE_PATH} -scheme ${PROJECT_NAME} -sdk iphonesimulator -configuration ${CONFIGURATION} clean build CONFIGURATION_BUILD_DIR=${BUILD_DIR}/${CONFIGURATION}-iphonesimulator 2>&1


xcodebuild -project ${PROJECT_FILE_PATH} -scheme ${PROJECT_NAME} -sdk iphoneos -configuration ${CONFIGURATION} clean build CONFIGURATION_BUILD_DIR=${BUILD_DIR}/${CONFIGURATION}-iphoneos 2>&1


######################
# Create directory for universal
######################

rm -rf "${UNIVERSAL_LIBRARY_DIR}"

mkdir "${UNIVERSAL_LIBRARY_DIR}"

mkdir "${FRAMEWORK}"


######################
# Copy files Framework
######################

cp -r "${DEVICE_LIBRARY_PATH}/." "${FRAMEWORK}"


######################
# Make an universal binary
######################

lipo "${SIMULATOR_LIBRARY_PATH}/${FRAMEWORK_NAME}" "${DEVICE_LIBRARY_PATH}/${FRAMEWORK_NAME}" -create -output "${FRAMEWORK}/${FRAMEWORK_NAME}" | echo

# For Swift framework, Swiftmodule needs to be copied in the universal framework
if [ -d "${SIMULATOR_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftmodule/" ]; then
cp -f ${SIMULATOR_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftmodule/* "${FRAMEWORK}/Modules/${FRAMEWORK_NAME}.swiftmodule/" | echo
fi

if [ -d "${DEVICE_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftmodule/" ]; then
cp -f ${DEVICE_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftmodule/* "${FRAMEWORK}/Modules/${FRAMEWORK_NAME}.swiftmodule/" | echo
fi

######################
# On Release, copy the result to release directory
######################
OUTPUT_DIR="${PROJECT_DIR}/Output/${FRAMEWORK_NAME}-${CONFIGURATION}-iphoneuniversal/"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

cp -r "${FRAMEWORK}" "$OUTPUT_DIR"

if [ ${REVEAL_ARCHIVE_IN_FINDER} = true ]; then
open "${OUTPUT_DIR}/"
fi

```

### Project implementing SDK inside, alias as "SDK handler"
1. Xcode File > New > Project > Single View App (Or any other preferable one)
2. **Drag and drop [SDK Project Name].xcodeproj to either .xcodeproj or .xcworkspace of SDK handler**
3. Target > Linked Frameworks and Libraries '+' add binary in the Product folder of SDK project after building.
4. Xcode Product > Clean Build Folder, after updating framework binary


(Reference (JP): https://qiita.com/wai21/items/3a2a7a7170ab9c5c1952)



# 2. Pod Spec

```
$ pod lib create [Pod Name]
```

```
s.source           = { :git => [Pod Respository(.git, private)], :tag => s.version.to_s }
```
Note: [Private Repository] should be containing a tag, which is same with s.version

While developing pod spec, do validity check using this command:
```
cd [Directory with .podspec]
$ pod spec lint
```

```
$ pod repo add [Pod Spec Repository Name] [Pod Spec Repository(.git, public)]
Cloning spec repo `[Pod Spec Repository Name]` from `[Pod Spec Repository(.git, public)]`

$  pod repo push [Pod Spec Repository Name] [Podspec File(.podspec, from private Pod Repository)] --allow-warnings

Validating spec
-> [Pod Name] ([s.version])
- NOTE  | xcodebuild:  note: Using new build system
- NOTE  | [iOS] xcodebuild:  note: Planning build
- NOTE  | [iOS] xcodebuild:  note: Constructing build description
- NOTE  | [iOS] xcodebuild:  warning: Skipping code signing because the target does not have an Info.plist file. (in target 'App')

Updating the `[Pod Spec Repository Name]' repo


Adding the spec to the `[Pod Spec Repository Name]' repo

- [Add] [Pod Name] ([s.version])

Pushing the `[Pod Spec Repository Name]' repo
```


# 2-1. Error Cases

#### Description
* I have encountered an error, which is "An unexpected version directory `Classes` was encountered for ... "
* (I am not using the Assets directory. In case using the Assets, you might encounter an error, which is "An unexpected version directory `Assets` was encountered for ... ")

#### Solution
* Follow the steps above to separate the pod spec repository.

#### Bypass
It is NOT recommended, but in the case if you want to share repository of Pod and Pod Spec, please follow as below:
1. By default, s.source_files in podspec is defined as below:
```
s.source_files = '[Pod Name]/Classes/**/*' 
```
2. Modify this part, for example (*)
```
s.source_files = 'Source/Classes/**/*.{swift}'
```
3. In this case, Pod Spec will be added to  following directory:
```
[Pod Name]/[s.version]
```
4. Following will be the tree when following the example (*) above.
```
SelfImproverSDK
├── Example
│   ├── (omitted)
├── LICENSE
├── README.md
├── SelfImproverSDK
│   ├── 0.1.0
│   │   └── SelfImproverSDK.podspec
│   ├── 0.1.1
│   │   └── SelfImproverSDK.podspec
│   └── 0.1.2
│       └── SelfImproverSDK.podspec
├── SelfImproverSDK.podspec
├── Source
│   ├── Assets
│   └── Classes
│       └── (omitted)
└── _Pods.xcodeproj -> Example/Pods/Pods.xcodeproj
```

# 3. Import Pod

An example of Podfile in order to import the private pod.

```
platform :ios, '11.0'
source "https://github.com/HanaisMe/SelfImproverSDK-Podspec.git"
source "https://github.com/CocoaPods/Specs.git"

use_frameworks!

def default_pods
pod 'AppCenter'
pod 'Firebase/Core'
pod 'Fabric', '~> 1.9.0'
pod 'Crashlytics', '~> 3.12.0'
pod 'RealmSwift'
end

target '[Project Name]' do
default_pods
pod 'SelfImproverSDK'
pod 'Google-Mobile-Ads-SDK'
end

target 'TodayExtension' do
default_pods
end
```

Notes
* Beware of s.ios.deployment_target of the Podspec
* Require Only App-Extension-Safe API
    > Make sure your embedded framework does not contain APIs unavailable to app extensions, as described in Some APIs Are Unavailable to App Extensions. If you have a custom framework that does contain such APIs, you can safely link to it from your containing app but cannot share that code with the app’s contained extensions. The App Store rejects any app extension that links to such frameworks or that otherwise uses unavailable APIs. (https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html)
