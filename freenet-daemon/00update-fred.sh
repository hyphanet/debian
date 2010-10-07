#!/bin/sh

FREENET_VERSION_RELEASED=0.7.5

USAGE="Usage: $0 [-s|-u|-h] [--] [BRANCH]"
BOPT_ORIG_ONLY=false
BOPT_DPKG=""
BOPT_UPDATE=false

while getopts oSuh o; do
	case $o in
	o ) BOPT_ORIG_ONLY=true;;
	S ) BOPT_DPKG="$BOPT_DPKG -S";;
	u ) BOPT_UPDATE=true;;
	h )
		cat <<-EOF
		$USAGE

		Build Freenet from fred-BRANCH and contrib-BRANCH into the freenet-daemon
		debian package.

		  -h            This help text.
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

FREENET_BRANCH="$1"
if [ -z "$FREENET_BRANCH" ]; then FREENET_BRANCH=official; fi
if ! [ -d fred-${FREENET_BRANCH} ]; then echo "not a directory: fred-${FREENET_BRANCH}"; echo "$USAGE"; exit 1; fi
if ! [ -d contrib-${FREENET_BRANCH} ]; then echo "not a directory: contrib-${FREENET_BRANCH}"; echo "$USAGE"; exit 1; fi

GIT_DESCRIBED="$(cd fred-${FREENET_BRANCH} && git describe --always --abbrev=4 && cd ..)"
DEB_VERSION=${FREENET_VERSION_RELEASED}+${GIT_DESCRIBED}
DEB_REVISION="$(dpkg-parsechangelog | grep Version | cut -d- -f2)"

BUILD_DIR="freenet-daemon-${DEB_VERSION}"
DIST_DIR="freenet-daemon-${FREENET_BRANCH}-dist"

log 0 "building freenet-daemon in $BUILD_DIR/"
log 0 "packages will be saved to $DIST_DIR/"

#PS4="\[\033[01;34m\]\w\[\033[00m\]\$ "
#set -x

if $BOPT_UPDATE; then
	log 1 "updating repos..."
	cd fred-${FREENET_BRANCH} && git pull origin && cd ..
	cd contrib-${FREENET_BRANCH} && git pull origin && cd ..
fi

log 1 "cleaning previous build products..."
rm -rf "$BUILD_DIR"
rm -rf "$DIST_DIR"
rm -f *.orig.tar.bz2 *.tmpl.tar.gz
rm -f *.changes *.deb *.dsc *.debian.tar.gz
mkdir "$BUILD_DIR" || exit 1
mkdir "$DIST_DIR" || exit 1

log 1 "copying and editing source files..."
cp -aH fred-${FREENET_BRANCH} contrib-${FREENET_BRANCH} "$BUILD_DIR" || exit 1
cd "$BUILD_DIR"
# remove cruft
for path in fred-${FREENET_BRANCH} contrib-${FREENET_BRANCH}; do
	cd "$path"
	git clean -qfdx
	find . -name .git -o -name .gitignore -o -name .cvsignore | xargs rm -rf
	cd ..
done
# point fred to contrib
echo "contrib.dir=../contrib-${FREENET_BRANCH}/freenet_ext" >> fred-${FREENET_BRANCH}/build.properties
cd ..

log 1 "making original source archives..."
tar cfj freenet-daemon_${DEB_VERSION}.orig.tar.bz2 "$BUILD_DIR"
cp freenet-daemon_${DEB_VERSION}.orig.tar.bz2 "$DIST_DIR"
tar cfz debian.freenet-daemon.tmpl.tar.gz debian
cp debian.freenet-daemon.tmpl.tar.gz "$DIST_DIR"

log 1 "copying and editing debian packaging files..."
cp -a debian "$BUILD_DIR"/debian
cd "$BUILD_DIR"/debian
# update seednodes
rm -rf seednodes.fref && wget -q -O seednodes.fref http://downloads.freenetproject.org/alpha/opennet/seednodes.fref
# substitute variables
ls -1 copyright freenet-daemon.docs rules | xargs sed -i \
	-e 's/@RELEASE@/'${FREENET_BRANCH}'/g' \
	-e 's/@REVISION@/'${GIT_DESCRIBED}'/g'
cd ../..

if $BOPT_ORIG_ONLY; then exit; fi

log 1 "building debian packages..."
cd "$BUILD_DIR"
dch -v ${DEB_VERSION}-${DEB_REVISION} "GIT SNAPSHOT RELEASE! TEST PURPOSE ONLY!" && dpkg-buildpackage -rfakeroot $BOPT_DPKG
cd ..

log 1 "saving built packages..."
mv *.changes *.deb *.dsc *.debian.tar.gz "$DIST_DIR"
cd "$DIST_DIR"
dpkg-scanpackages . /dev/null > Packages
gzip -9 Packages
dpkg-scansources . /dev/null > Sources
gzip -9 Sources
cd ..
