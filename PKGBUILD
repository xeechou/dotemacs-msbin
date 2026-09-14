# Maintainer: Martell Malone <martellmalone@gmail.com>

_realname=dotemacs-bin
pkgbase=mingw-w64-${_realname}
pkgname=("${_realname}")
pkgver=v0.2.4
pkgrel=1
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
	 "${MINGW_PACKAGE_PREFIX}-imagemagick"
	 "${MINGW_PACKAGE_PREFIX}-python"
	 # basedpyright dropped: it is the only package in the closure that pulls
	 # in nodejs (~52MB of lib/node_modules plus node.exe), and the bare/.exe
	 # wrapper pairs it ships trip the MSYS .exe name magic in package().
	 # python-lsp-ruff is a pylsp plugin and needs no node.
	 # "${MINGW_PACKAGE_PREFIX}-basedpyright"
	 "${MINGW_PACKAGE_PREFIX}-python-lsp-ruff"
	 "coreutils" #for printf
	 "${MINGW_PACKAGE_PREFIX}-binutils"  #for objdump, nm, c++filt
	 # "${MINGW_PACKAGE_PREFIX}-texlive-bin" too much more bloated
	 # "${MINGW_PACKAGE_PREFIX}-texlive-plain-generic"
	 # "${MINGW_PACKAGE_PREFIX}-texlive-latex-recommended"
	)
makedepends=("wget" "pacman-contrib" "curl" "git")
source=("dict.sh" "dict.txt")
sha256sums=('SKIP' 'SKIP')
dictref="libreoffice-26.2.6.3"

pkg_download() {
    mkdir -p "$2"
    /usr/bin/curl --connect-timeout 15 -Lf "$1" -o "$2/$(basename $1)"
}

# The ca-certificates package ships everything under etc/ as empty placeholders
# and relies on its .INSTALL post_install hook calling update-ca-trust to
# generate the real bundles from share/pki/ca-trust-source. We only untar the
# packages, so that hook never runs: every CA bundle ships as 0 bytes and curl,
# git-over-https, wget and anything else OpenSSL-linked fail with "unable to get
# local issuer certificate". This replicates update-ca-trust against the
# unpacked tree. We cannot call the shipped update-ca-trust itself: it hardcodes
# DEST=${MINGW_PREFIX}/etc/... which only resolves inside an MSYS2 shell rooted
# at the install prefix.
ca_trust_extract() {
    local prefix p11kit dest dest_w f

    for prefix in "${srcdir}"/unpack/*/; do
	prefix="${prefix%/}"
	[ -d "${prefix}/share/pki/ca-trust-source" ] || continue

	p11kit="${prefix}/bin/p11-kit.exe"
	if [ ! -f "${p11kit}" ]; then
	    echo "ca_trust_extract: ${p11kit} missing, cannot generate CA bundles" >&2
	    return 1
	fi

	echo "ca_trust_extract: generating CA trust bundles in ${prefix}"
	dest="${prefix}/etc/pki/ca-trust/extracted"
	mkdir -p "${dest}/openssl" "${dest}/pem" "${dest}/java"

	# p11-kit is relocatable: it reads the trust sources next to its own
	# bin/, so this extracts from the unpacked tree and not from the build
	# host's prefix. It is a native binary, so hand it a Windows path.
	dest_w=$(cygpath -w "${dest}")

	"${p11kit}" extract --format=openssl-bundle --filter=certificates \
		    --overwrite --comment "${dest_w}\openssl\ca-bundle.trust.crt"
	"${p11kit}" extract --format=pem-bundle --filter=ca-anchors \
		    --overwrite --comment --purpose server-auth \
		    "${dest_w}\pem\tls-ca-bundle.pem"
	"${p11kit}" extract --format=pem-bundle --filter=ca-anchors \
		    --overwrite --comment --purpose email \
		    "${dest_w}\pem\email-ca-bundle.pem"
	"${p11kit}" extract --format=pem-bundle --filter=ca-anchors \
		    --overwrite --comment --purpose code-signing \
		    "${dest_w}\pem\objsign-ca-bundle.pem"
	"${p11kit}" extract --format=java-cacerts --filter=ca-anchors \
		    --overwrite --purpose server-auth "${dest_w}\java\cacerts"

	# Upstream these three are symlinks into extracted/, but tar flattens
	# symlinks into empty regular files on Windows, so update-ca-trust alone
	# would never fix the paths curl actually reads. Write real copies.
	mkdir -p "${prefix}/etc/ssl/certs"
	cp "${dest}/pem/tls-ca-bundle.pem"       "${prefix}/etc/ssl/certs/ca-bundle.crt"
	cp "${dest}/openssl/ca-bundle.trust.crt" "${prefix}/etc/ssl/certs/ca-bundle.trust.crt"
	cp "${dest}/pem/tls-ca-bundle.pem"       "${prefix}/etc/ssl/cert.pem"

	# Fail the build rather than shipping empty bundles again.
	# objsign-ca-bundle.pem is deliberately not checked: the Mozilla trust
	# store carries no code-signing anchors, so it is legitimately empty.
	for f in "${dest}/openssl/ca-bundle.trust.crt" \
		 "${dest}/pem/tls-ca-bundle.pem" \
		 "${dest}/pem/email-ca-bundle.pem" \
		 "${dest}/java/cacerts" \
		 "${prefix}/etc/ssl/certs/ca-bundle.crt" \
		 "${prefix}/etc/ssl/certs/ca-bundle.trust.crt" \
		 "${prefix}/etc/ssl/cert.pem"; do
	    if [ ! -s "${f}" ]; then
		echo "ca_trust_extract: ${f} is empty, CA trust generation failed" >&2
		return 1
	    fi
	done
    done
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
    # either https://git.libreoffice.org/dictionaries or github
    git clone -b ${dictref} https://github.com/LibreOffice/dictionaries.git dict
    cd "${srcdir}" # now copy the dictionaries
    ./dict.sh dict "${srcdir}/unpack/$(basename ${MINGW_PREFIX})/share/hunspell"

    # regenerate the CA bundles that the ca-certificates .INSTALL hook would
    # normally produce; without this every bundle under etc/ ships as 0 bytes
    ca_trust_extract || return 1
}

package() {
    cd "${srcdir}/unpack"
    #MINGW_PREFIX is actually "/mingw64", and need to skip
    #since right now we copy both /mingw64 and /usr, we just directly copy
    #whatever that's in unpack
    cp -r "${srcdir}/unpack"/* "${pkgdir}/"
}
