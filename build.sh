#!/usr/bin/env bash
# shellcheck source=prepare_env.sh
function prepare_env() {
  if [ -r ~/prepare_env.sh ]; then
    . ~/prepare_env.sh
  else
    echo "ERROR: ~/prepare_env.sh not found!"
    exit 1
  fi
}
prepare_env

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

function switch_android_arch() {
  arch=${1}
  file=${2}
  sed -i'' "s#^.*android.arch.*=.*\$#android.arch = ${arch}#g" "${file}"
}

function switch_ndk_path() {
    file=${1}
    echo "INFO: Setting android.ndk_path in ${file} to /usr/share/android/ndk"
    sed -i'' "s#^.*android.ndk_path.*=.*\$#android.ndk_path = /usr/share/android/ndk#g" "${file}"
}

function switch_sdk_path() {
    file=${1}
    echo "INFO: Setting android.sdk_path in ${file} to /usr/share/android/sdk"
    sed -i'' "s#^.*android.sdk_path.*=.*\$#android.sdk_path = /usr/share/android/sdk#g" "${file}"
}

function switch_ant_path() {
    file=${1}
    echo "INFO: Setting android.ant_path in ${file} to /usr/share/android/ant"
    sed -i'' "s#^.*android.ant_path.*=.*\$#android.ant_path = /usr/share/android/ant#g" "${file}"
}

function switch_p4a_path() {
    file=${1}
    echo "INFO: Setting p4a.source_dir in ${file} to /usr/share/android/p4a"
    sed -i'' "s#^.*p4a.source_dir.*=.*\$#p4a.source_dir = /usr/share/android/p4a#g" "${file}"
}

function warn_on_root_disable() {
  file=${1}
  echo "INFO: Disabling warn_on_root in ${file}"
  sed -i'' "s#^.*warn_on_root.*=.*\$#warn_on_root = 0#g" "${file}"
}

function auto_accept_sdk_license() {
  file=${1}
  echo "INFO: Enabling android.accept_sdk_license in ${file}"
  sed -i'' "s#^.*android.accept_sdk_license.*=.*\$#android.accept_sdk_license = True#g" "${file}"
}

cd /app/build || exit

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
