#!/bin/bash

# debugging purposes
set -e
set -x
echo "#####################################################################"
set
echo "#####################################################################"

# repo https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo
repo init -b albacore -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo
repo sync

# save current manifest
repo manifest -r > ${MACHINE}_default.xml

# clean it up
mv agl-albacore-$MACHINE agl-albacore-${MACHINE}_2 || true
ionice rm -rf agl-albacore-${MACHINE}_2 &

echo "#####################################################################"

# create shared downloads and sstate-cache
mkdir -p ../downloads
mkdir -p ../sstate-cache

# source the env
source meta-agl/scripts/envsetup.sh $MACHINE agl-albacore-$MACHINE

# only if sequential - global dl/sstate-cache !
ln -sf ../../downloads
ln -sf ../../sstate-cache

#echo "" >> conf/local.conf
#echo 'INHERIT += "rm_work"' >> conf/local.conf

# archive sources within  tmp/deploy/
echo 'INHERIT += "archiver"' >> conf/local.conf
echo 'ARCHIVER_MODE[src] = "original"' >> conf/local.conf

echo 'IMAGE_INSTALL_append = " CES2016-demo mc"' >> conf/local.conf

if test x"qemux86" == x"$MACHINE" -o x"qemux86-64" == x"$MACHINE" ; then
 echo 'IMAGE_FSTYPES = "tar.bz2 vmdk"' >> conf/local.conf
fi


# build it
bitbake agl-demo-platform


# prepare RELEASE dir for rsyncing

mv RELEASE RELEASE2 || true
rm -rf RELEASE2 || true
mkdir -p RELEASE/albacore/${RELEASEVERSION}/${MACHINE}
export DEST=$(pwd)/RELEASE/albacore/${RELEASEVERSION}/${MACHINE}
export RSYNCSRC=$(pwd)/RELEASE/


rsync -avr --progress --delete tmp/deploy $DEST/
rsync -avr --progress --delete tmp/log $DEST/

cp ../${MACHINE}_default.xml $DEST/${MACHINE}_repo_default.xml
cp conf/local.conf $DEST/local.conf
echo "$BUILD_URL" > $DEST/jenkins.build.url

#debug
tree $DEST

# rsync to download server
rsync -avr $RSYNCSRC 172.30.4.151::repos/release/

# create latest symlink
pushd $RSYNCSRC/albacore/
rm -rf latest || true
ln -sf ${RELEASEVERSION} latest
echo "${RELEASEVERSION}" > latest.txt
popd

#resync with link
rsync -alvr $RSYNCSRC 172.30.4.151::repos/release/
