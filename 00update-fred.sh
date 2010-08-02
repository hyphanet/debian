#!/bin/sh
FREENET_VERSION_RELEASED=0.7.5
DEB_REVISION=0.1

FREENET_BRANCH=$1
if [ -z "$1" ]; then
  FREENET_BRANCH=official
fi

cd fred-${FREENET_BRANCH} && git pull origin && ant distclean && cd ..
cd contrib-${FREENET_BRANCH} && git pull origin && cd freenet_ext && ant clean
cd ../..

GIT_DESCRIBED=$(cd fred-${FREENET_BRANCH} && git describe && cd ..)
DEB_VERSION=${FREENET_VERSION_RELEASED}+${GIT_DESCRIBED}

rm -rf fred-${DEB_VERSION}
rm -rf fred-${FREENET_BRANCH}-dist
rm -f *.changes *.deb *.dsc *.debian.tar.gz *.orig.tar.bz2

mkdir fred-${DEB_VERSION}
cp -R fred-${FREENET_BRANCH} contrib-${FREENET_BRANCH} fred-${DEB_VERSION}
find fred-${DEB_VERSION}/fred-${FREENET_BRANCH} -name .git|xargs rm -rf
find fred-${DEB_VERSION}/fred-${FREENET_BRANCH} -name .cvsignore|xargs rm -rf
find fred-${DEB_VERSION}/fred-${FREENET_BRANCH} -name .gitignore|xargs rm -rf
find fred-${DEB_VERSION}/contrib-${FREENET_BRANCH} -name .git|xargs rm -rf
tar cfj fred_${DEB_VERSION}.orig.tar.bz2 fred-${DEB_VERSION}

rm -f debian/seednodes.fref
wget -O debian/seednodes.fref http://downloads.freenetproject.org/alpha/opennet/seednodes.fref

cp -R debian fred-${DEB_VERSION}/debian
find fred-${DEB_VERSION}/debian -name copyright | xargs sed -i 's/@RELEASE@/'${FREENET_BRANCH}'/g'
find fred-${DEB_VERSION}/debian -name fred.docs | xargs sed -i 's/@RELEASE@/'${FREENET_BRANCH}'/g'
find fred-${DEB_VERSION}/debian -name rules | xargs sed -i 's/@RELEASE@/'${FREENET_BRANCH}'/g'
find fred-${DEB_VERSION}/debian -name rules | xargs sed -i 's/@REVISION@/'${GIT_DESCRIBED}'/g'

cd fred-${DEB_VERSION} && dch -v ${DEB_VERSION}-${DEB_REVISION} "GIT SNAPSHOT RELEASE! TEST PURPOSE ONLY!" && dpkg-buildpackage -rfakeroot && cd ..

mkdir fred-${FREENET_BRANCH}-dist
mv *.changes *.deb *.dsc *.debian.tar.gz *.orig.tar.bz2 fred-${FREENET_BRANCH}-dist

rm -f debian/seednodes.fref
tar cfz debian.fred.tmpl.tar.gz debian
cp debian.fred.tmpl.tar.gz fred-${FREENET_BRANCH}-dist

cd fred-${FREENET_BRANCH}-dist
dpkg-scanpackages . /dev/null > Packages
gzip -9 Packages
dpkg-scansources . /dev/null > Sources
gzip -9 Sources
