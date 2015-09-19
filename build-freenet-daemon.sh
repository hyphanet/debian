#!/bin/sh

PACKAGE=freenet-daemon
FREENET_VERSION_RELEASED=0.7.5
DEV_BUILD=true

BOPTS=cuoS
USAGE="Usage: $0 [-$BOPTS] [-h] [--]"
BOPT_CLEAN_ONLY=false
BOPT_UPDATE=false
BOPT_ORIG_ONLY=false
BOPT_DPKG=""

while getopts h$BOPTS o; do
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
		exit
		;;
	\? ) echo $USAGE; exit 2;;
	esac
done
shift `expr $OPTIND - 1`

if [ "$(dirname "$0")" != "." -o ! -d ".git" ]; then
	echo >&2 "must be run as ./$(basename "$0") from the debian-staging git repo"
	exit 1
fi

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

set -o errexit

log 0 "build ${PACKAGE}"

#PS4="\[\033[01;34m\]\w\[\033[00m\]\$ "
#set -x

log 1 "clean previous build products..."
rm -f ${PACKAGE}_* Packages.gz Sources.gz
if $BOPT_CLEAN_ONLY; then exit; fi

if $BOPT_UPDATE; then
	log 1 "update sources..."
	cd ${REPO_FRED} && git pull origin && cd -
	cd ${REPO_EXT} && git pull origin && cd -
	# update seednodes
	cd ${PACKAGE}/debian
	wget -N http://downloads.freenetproject.org/alpha/opennet/seednodes.fref
	cd -
fi

log 1 "update submodules..."
git submodule update --init

log 1 "clean source repos..."
for path in ${REPO_FRED} ${REPO_EXT}; do
	cd "$path" && git reset --hard HEAD && git clean -fd && cd -
done

log 1 "build source archives..."
tar -cj --exclude-vcs --exclude=${PACKAGE}/debian \
  -f ${PACKAGE}_${DEB_VERSION}.orig.tar.bz2 ${PACKAGE}
tar -cz --exclude-vcs \
  -f ${PACKAGE}_${DEB_VERSION}.debian.tar.gz ${PACKAGE}/debian

if $BOPT_ORIG_ONLY; then exit; fi

log 1 "build debian binary packages..."
cd ${PACKAGE}
if $DEV_BUILD; then
	CHLOG="$PWD/debian/changelog"
	cp "$CHLOG" "$CHLOG.old"
	dch -v ${DEB_VERSION}-${DEB_REVISION} "GIT SNAPSHOT RELEASE! TEST PURPOSE ONLY!"
	undch() { if [ -f "$CHLOG.old" ]; then mv "$CHLOG.old" "$CHLOG"; fi }
	trap undch EXIT INT TERM KILL
	echo "\033[36;1m$CHLOG\033[m has been modified; \033[31;1mplease do NOT commit it to source control.\033[m It will be reverted when this command exits or is aborted."
fi
dpkg-buildpackage -rfakeroot $BOPT_DPKG
cd ..

dpkg-scanpackages . | gzip -9 > Packages.gz
dpkg-scansources . | gzip -9 > Sources.gz
