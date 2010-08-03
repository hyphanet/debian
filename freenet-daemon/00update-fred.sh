#!/bin/sh
FREENET_VERSION_RELEASED=0.7.5
DEB_REVISION=0.1

FREENET_BRANCH=$1
if [ -z "$1" ]; then
  FREENET_BRANCH=official
fi

BITS="-Dbits=32"
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" -o "$ARCH" = "amd64" ]; then
	BITS="-Dbits=64";
fi

cd fred-${FREENET_BRANCH} && git pull origin && ant distclean && cd ..
cd contrib-${FREENET_BRANCH} && git pull origin && cd freenet_ext && ant clean ${BITS} && cd ../..

GIT_DESCRIBED=$(cd fred-${FREENET_BRANCH} && git describe && cd ..)
DEB_VERSION=${FREENET_VERSION_RELEASED}+${GIT_DESCRIBED}

rm -rf freenet-daemon-${DEB_VERSION}
rm -rf freenet-daemon-${FREENET_BRANCH}-dist
rm -f *.changes *.deb *.dsc *.debian.tar.gz *.orig.tar.bz2

mkdir freenet-daemon-${DEB_VERSION}
cp -alL fred-${FREENET_BRANCH} contrib-${FREENET_BRANCH} freenet-daemon-${DEB_VERSION}
find freenet-daemon-${DEB_VERSION}/fred-${FREENET_BRANCH} -name .git|xargs rm -rf
find freenet-daemon-${DEB_VERSION}/fred-${FREENET_BRANCH} -name .cvsignore|xargs rm -rf
find freenet-daemon-${DEB_VERSION}/fred-${FREENET_BRANCH} -name .gitignore|xargs rm -rf
find freenet-daemon-${DEB_VERSION}/contrib-${FREENET_BRANCH} -name .git|xargs rm -rf
tar cfj freenet-daemon_${DEB_VERSION}.orig.tar.bz2 freenet-daemon-${DEB_VERSION}

rm -f debian/seednodes.fref
wget -O debian/seednodes.fref http://downloads.freenetproject.org/alpha/opennet/seednodes.fref

cp -R debian freenet-daemon-${DEB_VERSION}/debian
find freenet-daemon-${DEB_VERSION}/debian -name copyright | xargs sed -i 's/@RELEASE@/'${FREENET_BRANCH}'/g'
find freenet-daemon-${DEB_VERSION}/debian -name freenet-daemon.docs | xargs sed -i 's/@RELEASE@/'${FREENET_BRANCH}'/g'
find freenet-daemon-${DEB_VERSION}/debian -name rules | xargs sed -i 's/@RELEASE@/'${FREENET_BRANCH}'/g'
find freenet-daemon-${DEB_VERSION}/debian -name rules | xargs sed -i 's/@REVISION@/'${GIT_DESCRIBED}'/g'

cd freenet-daemon-${DEB_VERSION} && dch -v ${DEB_VERSION}-${DEB_REVISION} "GIT SNAPSHOT RELEASE! TEST PURPOSE ONLY!" && dpkg-buildpackage -rfakeroot && cd ..

mkdir freenet-daemon-${FREENET_BRANCH}-dist
mv *.changes *.deb *.dsc *.debian.tar.gz *.orig.tar.bz2 freenet-daemon-${FREENET_BRANCH}-dist

rm -f debian/seednodes.fref
tar cfz debian.freenet-daemon.tmpl.tar.gz debian
cp debian.freenet-daemon.tmpl.tar.gz freenet-daemon-${FREENET_BRANCH}-dist

cd freenet-daemon-${FREENET_BRANCH}-dist
dpkg-scanpackages . /dev/null > Packages
gzip -9 Packages
dpkg-scansources . /dev/null > Sources
gzip -9 Sources
