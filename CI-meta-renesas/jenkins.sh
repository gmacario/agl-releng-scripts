#!/bin/bash

# debugging purposes
set -e
set -x

# create shared downloads and sstate-cache directory
mkdir -p downloads
mkdir -p sstate-cache

# remove old files, we want to test a fresh clone
mv repoclone repoclone2 || true
( nice rm -rf repoclone2 & ) || true
mkdir repoclone
cd repoclone

# check if master or branch
if test x"" != x"$GERRIT_BRANCH"; then
  repo init -b $GERRIT_BRANCH -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo
else
  echo ""
  echo "####################################################"
  echo "ATTENTION: NO GERRIT_BRANCH, using master by default"
  echo "####################################################"
  echo ""
  repo init  -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo
fi

# next: repo sync and dump manifest
repo sync

# fix up this branch
cd meta-renesas

# we need to inject the git ref of GERRIT_PATCHSET_REVISION to the recipe
if test x"" != x"${GERRIT_PATCHSET_REVISION}" ; then
  git reset --hard ${GERRIT_PATCHSET_REVISION}
else
  echo "Something is wrong, we have no GERRIT_PATCHSET_REVISION. Exit."
  exit 1
fi


repo manifest -r
repo manifest -r > ../current_default.xml

# source the env
source meta-agl/scripts/envsetup.sh porter

# link the shared downloads and sstate-cache
ln -sf ../../downloads
ln -sf ../../sstate-cache

echo "" >> conf/local.conf
echo 'IMAGE_INSTALL_append = " mc"' >> conf/local.conf

# finally, build the agl-demo-platform
bitbake agl-demo-platform || exit 1
du -hs tmp/deploy/*

# create the archive
mkdir archive
cp ../../current_default.xml archive/
cp conf/local.conf archive/
tar -C tmp/deploy -cf archive/licenses.tar licenses


echo "We provide the repo default.xml in the file current_default.xml."   > archive/README.sources
echo "This will pull down the yocto layers used to build this snapshot." >> archive/README.sources
echo ""                                                                  >> archive/README.sources
echo "After syncing repo with the above default.xml, simply follow"      >> archive/README.sources
echo "the steps in the README.md of meta-agl-demo"                       >> archive/README.sources
echo ""                                                                  >> archive/README.sources
echo "Source can be fetched with:"                                       >> archive/README.sources
echo "  bitbake -c fetchall agl-demo-platform"                           >> archive/README.sources
echo ""                                                                  >> archive/README.sources
echo "A mirror of all sources used is also available here:"              >> archive/README.sources
echo "  http://download.automotivelinux.org/AGL/mirror/"                 >> archive/README.sources
echo ""                                                                  >> archive/README.sources
echo "The AGL components are hosted at:"                                 >> archive/README.sources
echo "  https://git.automotivelinux.org/"                                >> archive/README.sources
