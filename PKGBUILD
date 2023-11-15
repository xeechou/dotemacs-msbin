# Maintainer: Martell Malone <martellmalone@gmail.com>

_realname=dotemacs-bin
pkgbase=mingw-w64-${_realname}
pkgname=("${_realname}")
pkgver=v0.2.2
pkgrel=3
pkgdesc="Binaries dependencies for Emacs on Windows"
arch=('any')
mingw_arch=('mingw32' 'mingw64' 'ucrt64' 'clang64' 'clang32' 'clangarm64')
options=(!strip)
url='https://github.com/xeechou/dotemacs-msbin'
license=('MIT')
depends=("${MINGW_PACKAGE_PREFIX}-hunspell"
         "${MINGW_PACKAGE_PREFIX}-ripgrep"
         "${MINGW_PACKAGE_PREFIX}-sqlite3"
         "${MINGW_PACKAGE_PREFIX}-ninja"
         "${MINGW_PACKAGE_PREFIX}-curl"
         "${MINGW_PACKAGE_PREFIX}-diffutils"
         "coreutils" #for printf
         "${MINGW_PACKAGE_PREFIX}-binutils"  #for objdump, nm, c++filt
         # "${MINGW_PACKAGE_PREFIX}-texlive-bin" too much more bloated
         # "${MINGW_PACKAGE_PREFIX}-texlive-plain-generic"
         # "${MINGW_PACKAGE_PREFIX}-texlive-latex-recommended"
        )
makedepends=("wget" "pacman-contrib" "curl" "git")
source=("dict.sh" "dict.txt")
sha256sums=('SKIP' 'SKIP')
# dictref="9ec31e4"
dictref="libreoffice-7.6.0.2"

pkg_download() {
    mkdir -p "$2"
    /usr/bin/curl --connect-timeout 15 -Lf "$1" -o "$2/$(basename $1)"
}

prepare() {
    # the prepare functions will generate the packages.list which contains
    # default urls of the packages.
    cd "${srcdir}/"
    # get the dependencies: "xargs -n 1" will execute the command once per
    # parameter, "pacman -Sp" will generate the default URL to download
    echo "${depends[@]}" | xargs -n 1 pactree -u | \
        sort -u | \
        xargs -n 1 pacman -Sp > _packages.list
    echo "Prepare: packages to download:"
    cat _packages.list

    # Download packages under the cache
    packages=$(cat _packages.list)
    for url in ${packages}; do
        pkg_download "$url" "${srcdir}/cache"
    done
}

build() {
    cd "${srcdir}/"
    mkdir -p unpack
    # tar accepts "axf" option now which use whatever the decompressor requires
    for f in cache/*.tar.*; do
        tar -axf "$f" -C "${srcdir}/unpack"
    done

    # # clone dictionaries because mingw only has en dictionaries
    cd "${srcdir}"
    rm -rf dict #clearing out the dictionary
    git clone -b ${dictref} https://anongit.freedesktop.org/git/libreoffice/dictionaries.git dict
    # cd dict && git checkout ${dictref} && patch -p1 < ../001-en_US.patch
    cd "${srcdir}" # now copy the dictionaries
    ./dict.sh dict "${srcdir}/unpack/$(basename ${MINGW_PREFIX})/share/hunspell"
}

package() {
    cd "${srcdir}/unpack"
    #MINGW_PREFIX is actually "/mingw64", and need to skip
    #since right now we copy both /mingw64 and /usr, we just directly copy
    #whatever that's in unpack
    cp -r "${srcdir}/unpack"/* "${pkgdir}/"
}
