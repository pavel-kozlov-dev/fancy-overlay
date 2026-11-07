# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=(python3_{12..14})

inherit desktop distutils-r1 pypi

DESCRIPTION="Cast media from Jellyfin Mobile and Web apps to MPV"
HOMEPAGE="https://github.com/jellyfin/jellyfin-mpv-shim
	https://pypi.org/project/jellyfin-mpv-shim/"
MY_AP_PV="1.21.0"
# python-mpv-jsonipc and pystray are also missing from ::gentoo, hence
# bundled the same way (see the monolith note at RDEPEND).
MY_JIPC_PV="1.5.0"
MY_PI_PV="0.19.5"
SRC_URI="
	$(pypi_sdist_url)
	$(pypi_sdist_url jellyfin-apiclient-python ${MY_AP_PV})
	$(pypi_sdist_url python-mpv-jsonipc ${MY_JIPC_PV})
	$(pypi_wheel_url pystray ${MY_PI_PV} py2.py3 none-any)
"
MY_AP_S="${WORKDIR}/jellyfin_apiclient_python-${MY_AP_PV}"
MY_JIPC_S="${WORKDIR}/python_mpv_jsonipc-${MY_JIPC_PV}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

# Upstream's suite is stdlib unittest, but eight modules import player.py,
# which opens a real mpv window at import time -- the suite has to run under
# an X display (upstream: xvfb-run -a python3 -m unittest discover tests).
# We deliberately skip running it rather than drag x11-base/xorg-server in
# as a test-only dependency.
RESTRICT="test"

# Four Python dependencies are bundled ("monolith"): none of
# jellyfin-apiclient-python, python-mpv-jsonipc or pystray (nor the earlier
# "no ebuilds to satisfy" problem) has a ::gentoo package, and the overlay
# prefers one ebuild per monolith. All three are pure Python:
# - jellyfin-apiclient-python 1.21.0 satisfies the shim's >=1.20.2 floor in
#   pyproject.toml; its runtime deps are urllib3 + websocket-client.
# - python-mpv-jsonipc 1.5.0 satisfies the shim's >=1.5.0 floor; no deps of
#   its own.
# - pystray 0.19.5 ships only a pure wheel on PyPI (no sdist since 0.19.4),
#   installed directly; its runtime deps on Linux are six + python-xlib.
# dev-python/python-mpv is the one of this group that *does* exist in
# ::gentoo; it pulls in >=media-video/mpv[libmpv].
# bundled pystray wheel.
# dev-python/pygobject provides the "gi" module used for MPRIS
# (Gio/GLib in mpris.py) and the tray icon: the bundled pystray is the
# systray framework, handing the icon to the desktop through the
# AppIndicator typelib.
# dev-libs/libayatana-appindicator[introspection] ships the
# AyatanaAppIndicator3 typelib that pystray's SNI/GTK backends load
# through gi.
# dev-python/six and dev-python/python-xlib are the runtime dependencies
# of the bundled pystray, on Linux.
RDEPEND="
	>=dev-python/certifi-2026.10.19
	dev-python/pillow
	dev-python/pygobject:3
	>=dev-python/python-mpv-1.0.8
	dev-python/python-xlib
	dev-python/requests
	dev-python/six
	dev-python/urllib3
	dev-python/websocket-client
	dev-libs/libayatana-appindicator[introspection]
"
BDEPEND=">=dev-python/setuptools-77"

python_compile() {
	distutils-r1_python_compile

	# Build the bundled jellyfin-apiclient-python into the same
	# per-implementation install tree, so python_install() merges both.
	# Upstream declares [build-system] requires but no build-backend key
	# (implicit setuptools); add a setup.py shim so the eclass resolves
	# the legacy setuptools backend it falls back on.
	(
		cd "${MY_AP_S}" || die
		[[ -f setup.py ]] || printf 'from setuptools import setup\nsetup()\n' > setup.py
		distutils_pep517_install "${BUILD_DIR}/install"
	)

	# Bundled python-mpv-jsonipc: standard PEP517 (explicit backend),
	# one py-module, no runtime deps.
	(
		cd "${MY_JIPC_S}" || die
		distutils_pep517_install "${BUILD_DIR}/install"
	)

	# Bundled pystray: PyPI ships only a pure wheel (no sdist at 0.19.5),
	# so reinstall the distfile wheel directly.
	distutils_wheel_install "${BUILD_DIR}/install" \
		"${DISTDIR}/pystray-${MY_PI_PV}-py2.py3-none-any.whl"
}

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
