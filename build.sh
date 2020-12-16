#!/usr/bin/env bash

# Define functions which are used several times below
#
# Remove leftover files, which are not needed for caching
# subsequent builds, replace symlinks with original files,
# etc.
#
function cleanup() {
  rm -rfv /app/build/.buildozer 2>/dev/null
  if [ -L /app/build/buildozer.spec ]; then
    rm -fv /app/build/buildozer.spec
  fi
  if [ -f /app/build/buildozer.spec.tmpl_orig ]; then
    mv -fv /app/build/buildozer.spec.tmpl_orig /app/build/buildozer.spec
  fi
}
cleanup

# Replace the 'android.arch' setting in the file provided (buildozer.spec).
# buildozer.spec MUST contain 'android.arch.*='; even if only commented out.
# This is required to have it set in the proper section.
#
function switch_android_arch() {
  arch=${1}
  file=${2}
  sed -i'' "s#^.*android.arch.*=.*\$#android.arch = ${arch}#g" "${file}"
}

# Replace the 'android.ndk_path' setting in the file provided (buildozer.spec).
# buildozer.spec MUST contain 'android.ndk_path.*='; even if only commented out.
# This is required to have it set in the proper section.
#
function switch_ndk_path() {
    file=${1}
    echo "INFO: Setting android.ndk_path in ${file} to /usr/share/android/ndk"
    sed -i'' "s#^.*android.ndk_path.*=.*\$#android.ndk_path = /usr/share/android/ndk#g" "${file}"
}

# Replace the 'android.sdk_path' setting in the file provided (buildozer.spec).
# buildozer.spec MUST contain 'android.sdk_path.*='; even if only commented out.
# This is required to have it set in the proper section.
#
function switch_sdk_path() {
    file=${1}
    echo "INFO: Setting android.sdk_path in ${file} to /usr/share/android/sdk"
    sed -i'' "s#^.*android.sdk_path.*=.*\$#android.sdk_path = /usr/share/android/sdk#g" "${file}"
}

# Replace the 'android.ant_path' setting in the file provided (buildozer.spec).
# buildozer.spec MUST contain 'android.ant_path.*='; even if only commented out.
# This is required to have it set in the proper section.
#
function switch_ant_path() {
    file=${1}
    echo "INFO: Setting android.ant_path in ${file} to /usr/share/android/ant"
    sed -i'' "s#^.*android.ant_path.*=.*\$#android.ant_path = /usr/share/android/ant#g" "${file}"
}

# Replace the 'p4a.source_dir' setting in the file provided (buildozer.spec).
# buildozer.spec MUST contain 'p4a.source_dir.*='; even if only commented out.
# This is required to have it set in the proper section.
#
function switch_p4a_path() {
    file=${1}
    echo "INFO: Setting p4a.source_dir in ${file} to /usr/share/android/p4a"
    sed -i'' "s#^.*p4a.source_dir.*=.*\$#p4a.source_dir = /usr/share/android/p4a#g" "${file}"
}

# Set 'warn_on_root' to 0 to not warn if buildozer is executed as root.
#
function warn_on_root_disable() {
  file=${1}
  echo "INFO: Disabling warn_on_root in ${file}"
  sed -i'' "s#^.*warn_on_root.*=.*\$#warn_on_root = 0#g" "${file}"
}

# Set 'warn_on_root' to 'True' to auto-accept any license dialogue.
#
function auto_accept_sdk_license() {
  file=${1}
  echo "INFO: Enabling android.accept_sdk_license in ${file}"
  sed -i'' "s#^.*android.accept_sdk_license.*=.*\$#android.accept_sdk_license = True#g" "${file}"
}

cd /app/build || exit

# Install Python requirements from the project
cd /app/build || exit
python -m pip install --pre -r requirements.txt
cd - || exit

## Pull most recent p4a Git commits
cd /usr/share/android/p4a || exit
git pull
cd - || exit

# Source /app/build/android_archs.sh which must contain an array
# declaration for 'dest_archs'. If this is not set (stays 0), only
# the current value for 'android.arch' will be build.
#
# If the array is declared and contains one or more archs, an APK
# build for each of them will be triggered.
# If there is a file called '/app/build/buildozer.spec.${arch}',
# it will be used as a definition for that arch's build.
# If not, '/app/build/buildozer.spec' will be copied to
# '/app/build/buildozer.spec.${arch}' and 'android.arch' in
# that copy will be set to the arch.
dest_archs=0
[[ -r /app/build/android_archs.sh ]] && . /app/build/android_archs.sh

if [ "${dest_archs}" != 0 ]; then
  # Multi-Arch build from android_archs.sh
  echo "INFO: Multi-Arch build: ${dest_archs[*]}"
  for arch in "${dest_archs[@]}"; do
    echo "INFO: Running build for arch ${arch}"
    if [ ! -f "/app/build/buildozer.spec.${arch}" ]; then
      if [ -f /app/build/buildozer.spec ]; then
        cp /app/build/buildozer.spec "/app/build/buildozer.spec.${arch}"
        switch_android_arch ${arch} "/app/build/buildozer.spec.${arch}"
        switch_ant_path "/app/build/buildozer.spec.${arch}"
        switch_sdk_path "/app/build/buildozer.spec.${arch}"
        switch_ndk_path "/app/build/buildozer.spec.${arch}"
        switch_p4a_path "/app/build/buildozer.spec.${arch}"
        warn_on_root_disable "/app/build/buildozer.spec.${arch}"
        auto_accept_sdk_license "/app/build/buildozer.spec.${arch}"
      else
        echo "ERROR: Neiter /app/build/buildozer.spec.${arch} nor /app/build/buildozer.spec found"
        exit 1
      fi
    fi
    if [ -f /app/build/buildozer.spec ]; then
      mv -fv /app/build/buildozer.spec /app/build/buildozer.spec.tmpl_orig
    fi
    ln -sv "buildozer.spec.${arch}" /app/build/buildozer.spec
    buildozer -v android "${1:-debug}"
    cleanup
  done
else
  # Single-Arch build from buildozer.spec
  echo "INFO: Single-Arch build: $(grep android.arch /app/build/buildozer.spec | cut -d '=' -f 2-)"
  if [ -f /app/build/buildozer.spec ]; then
    cp -fv /app/build/buildozer.spec /app/build/buildozer.spec.tmpl_orig
    switch_ant_path /app/build/buildozer.spec
    switch_sdk_path /app/build/buildozer.spec
    switch_ndk_path /app/build/buildozer.spec
    switch_p4a_path /app/build/buildozer.spec
    warn_on_root_disable /app/build/buildozer.spec
    auto_accept_sdk_license /app/build/buildozer.spec
    buildozer -v android "${1:-debug}"
    cleanup
  else
    echo "ERROR: /app/build/buildozer.spec not found!"
    exit 1
  fi
fi

# Not required, but also can't harm
cleanup
