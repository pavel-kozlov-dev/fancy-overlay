# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=(python3_{12..14})

inherit desktop distutils-r1 pypi

DESCRIPTION="Cast media from Jellyfin Mobile and Web apps to MPV"
HOMEPAGE="https://github.com/jellyfin/jellyfin-mpv-shim
	https://pypi.org/project/jellyfin-mpv-shim/"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

# Upstream's suite is stdlib unittest, but eight modules import player.py,
# which opens a real mpv window at import time -- the suite has to run under
# an X display (upstream: xvfb-run -a python3 -m unittest discover tests).
# We deliberately skip running it rather than drag x11-base/xorg-server in
# as a test-only dependency.
RESTRICT="test"

RDEPEND="
	>=dev-python/certifi-2026.10.19
	>=dev-python/jellyfin-apiclient-python-1.20.2
	dev-python/pillow
	dev-python/pygobject:3
	dev-python/pystray
	>=dev-python/python-mpv-1.0.8
	>=dev-python/python-mpv-jsonipc-1.5.0
	dev-python/requests
	dev-libs/libayatana-appindicator[introspection]
"
BDEPEND=">=dev-python/setuptools-77"

src_install() {
	distutils-r1_src_install

	newmenu jellyfin_mpv_shim/integration/com.github.iwalton3.jellyfin-mpv-shim.desktop \
		"${PN}.desktop"

	local size
	for size in 16 32 48 64 128 256; do
		newicon -s ${size} jellyfin_mpv_shim/integration/jellyfin-${size}.png \
			com.github.iwalton3.jellyfin-mpv-shim.png
	done
}
