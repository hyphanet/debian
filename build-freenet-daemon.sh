#!/bin/sh

PACKAGE=freenet-daemon
FREENET_VERSION_RELEASED=0.7.5
DEV_BUILD=true

USAGE="Usage: $0 [-c|-u|-o|-S|-h] [--]"
BOPT_CLEAN_ONLY=false
BOPT_UPDATE=false
BOPT_ORIG_ONLY=false
BOPT_DPKG=""

while getopts cuoSh o; do
	case $o in
	c ) BOPT_CLEAN_ONLY=true;;
	u ) BOPT_UPDATE=true;;
	o ) BOPT_ORIG_ONLY=true;;
	S ) BOPT_DPKG="$BOPT_DPKG -S";;
	h )
		cat <<-EOF
		$USAGE

		Build fred and contrib into the freenet-daemon debian package.

		  -h            This help text.
		  -c            Clean previous build products only.
		  -o            Only build original source tarball, no debian packages.
		  -S            Build debian source packages, but no binaries.
		  -u            Update (git-pull) repositories before building.
		EOF
		exit 1
		;;
	\? ) echo $USAGE; exit 1;;
	esac
done
shift `expr $OPTIND - 1`

log() {
	case $1 in 0 ) PREFIX="";; 1 ) PREFIX="- ";; esac
	shift
	echo "$PREFIX$@"
}

REPO_FRED=${PACKAGE}/fred
REPO_EXT=${PACKAGE}/contrib

GIT_DESCRIBED="$(cd ${REPO_FRED} && git describe --always --abbrev=4)"
GIT_DESCRIBED_EXT="$(cd ${REPO_EXT} && git describe --always --abbrev=4)"
DEB_VERSION=${FREENET_VERSION_RELEASED}+${GIT_DESCRIBED}
DEB_REVISION="$(cd ${PACKAGE} && dpkg-parsechangelog | grep Version | grep -o '\-[^-]*$' | tail -c+2)"

DIST_DIR="freenet-daemon-dist"

log 0 "building freenet-daemon; packages will be saved to $DIST_DIR/"

#PS4="\[\033[01;34m\]\w\[\033[00m\]\$ "
#set -x

log 1 "cleaning previous build products..."
rm -rf "$DIST_DIR"
rm -f *.orig.tar.bz2 *.tmpl.tar.gz
rm -f *.changes *.deb *.dsc *.debian.tar.gz
if $BOPT_CLEAN_ONLY; then exit; fi
mkdir "$DIST_DIR" || exit 1

if $BOPT_UPDATE; then
	log 1 "updating repos..."
	cd ${REPO_FRED} && git pull origin && cd -
	cd ${REPO_EXT} && git pull origin && cd -
	# update seednodes
	cd ${PACKAGE}/debian
	# FIXME: upstream bug prevents this from working for the moment
	#wget -N https://downloads.freenetproject.org/alpha/opennet/seednodes.fref.gpg || exit 1
	wget -N http://downloads.freenetproject.org/alpha/opennet/seednodes.fref.gpg || exit 1
	gpg --output seednodes.fref --decrypt seednodes.fref.gpg || exit 1
	rm -f seednodes.fref.gpg
	cd -
fi

log 1 "updating submodules..."
git submodule update || exit 1

log 1 "cleaning source repos..."
for path in ${REPO_FRED} ${REPO_EXT}; do
	cd "$path" && git reset --hard HEAD && git clean -fdx && cd - || exit 1
done

log 1 "making original source archives..."
tar --exclude-vcs -cjf freenet-daemon_${DEB_VERSION}.orig.tar.bz2 ${PACKAGE} || exit 1
cp freenet-daemon_${DEB_VERSION}.orig.tar.bz2 "$DIST_DIR" || exit 1
tar --exclude-vcs -czf debian.freenet-daemon.tmpl.tar.gz ${PACKAGE}/debian || exit 1
cp debian.freenet-daemon.tmpl.tar.gz "$DIST_DIR" || exit 1

if $BOPT_ORIG_ONLY; then exit; fi

log 1 "building debian packages..."
cd ${PACKAGE}
if $DEV_BUILD; then
	CHLOG=debian/changelog
	cp "$CHLOG" "$CHLOG.old" || exit 1
	dch -v ${DEB_VERSION}-${DEB_REVISION} "GIT SNAPSHOT RELEASE! TEST PURPOSE ONLY!" || exit 1
	undch() { if [ -f "$CHLOG.old" ]; then mv "$CHLOG.old" "$CHLOG"; fi }
	trap undch EXIT INT TERM KILL
	echo "\033[36;1m$CHLOG\033[m has been modified; \033[31;1mplease do NOT commit it to source control.\033[m It will be reverted when this command exits or is aborted."
fi
dpkg-buildpackage -rfakeroot $BOPT_DPKG || exit 1
cd ..

log 1 "saving built packages..."
mv *.changes *.deb *.dsc *.debian.tar.gz "$DIST_DIR"
cd "$DIST_DIR"
dpkg-scanpackages . /dev/null > Packages
gzip -9 Packages
dpkg-scansources . /dev/null > Sources
gzip -9 Sources
cd ..
