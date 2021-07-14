#!/usr/bin/env bash
set -ex

BUILDROOT="$(git rev-parse --show-toplevel)"

pushd "/tmp" &>/dev/null
  # Build and install libcbor
  git clone git://github.com/pjk/libcbor
  pushd "/tmp/libcbor" &>/dev/null
    git checkout v0.5.0
    cmake -Bbuild -H.
    cmake --build build -- --jobs=2 VERBOSE=1
    sudo make -j $(nproc) -C build install
  popd &>/dev/null

  # Build and install libfido2
  export PKG_CONFIG_PATH=/usr/local/opt/openssl@1.1/lib/pkgconfig
  git clone git://github.com/Yubico/libfido2
  pushd "/tmp/libfido2" &>/dev/null
    cmake -Bbuild -H.
    cmake --build build -- --jobs=2 VERBOSE=1
    sudo make -j $(nproc) -C build install
  popd &>/dev/null

  wget https://sourceforge.net/projects/pamtester/files/pamtester/0.1.2/pamtester-0.1.2.tar.gz -O - | tar -xz
  pushd "/tmp/pamtester-0.1.2" &>/dev/null
    autoreconf -i
    ./configure
    make
    sudo make install
  popd &>/dev/null
popd &>/dev/null

export DESTDIR="${BUILDROOT}/install"
pushd "$BUILDROOT" &>/dev/null
  ./autogen.sh
  ./configure --disable-silent-rules --disable-man
  make -j $(nproc)
  make install
popd &>/dev/null

mkdir -p ~/.config/Yubico/
touch ~/.config/Yubico/u2f_keys
echo "auth sufficient ${DESTDIR}/usr/lib/pam/pam_u2f.so debug" > dummy
sudo mv dummy /etc/pam.d/
sudo pamtester dummy $(whoami) authenticate
