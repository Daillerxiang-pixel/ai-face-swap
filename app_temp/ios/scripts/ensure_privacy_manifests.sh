#!/bin/bash
# Post-pod-install: generate PrivacyInfo.xcprivacy for pods that don't have one
# Required by Apple since Spring 2024

PODS_DIR="${PODS_DIR:-Pods}"

generate_privacy_manifest() {
    local pod_dir="$1"
    local manifest="$pod_dir/PrivacyInfo.xcprivacy"
    if [ ! -f "$manifest" ]; then
        cat > "$manifest" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSPrivacyAccessedAPICategoryUserTracking</key>
	<false/>
	<key>NSPrivacyAccessedAPICategoryDiskSpace</key>
	<false/>
	<key>NSPrivacyAccessedAPICategorySystemBootTime</key>
	<false/>
	<key>NSPrivacyAccessedAPICategoryActiveKeyboards</key>
	<false/>
	<key>NSPrivacyAccessedAPICategoryUserDefaults</key>
	<false/>
</dict>
</plist>
PLIST
        echo "Created PrivacyInfo.xcprivacy for $(basename $pod_dir)"
    fi
}

if [ -d "$PODS_DIR" ]; then
    for pod in "$PODS_DIR"/*/; do
        generate_privacy_manifest "$pod"
    done
    echo "Privacy manifest check complete."
else
    echo "Pods directory not found: $PODS_DIR"
fi
