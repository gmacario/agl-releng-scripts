#!/bin/bash

set -x
set -e

BASE_URL=https://build.automotivelinux.org/job/CI-meta-agl/ws/releng-scripts

curl -O ${BASE_URL}/.gitreview

for d in \
	CI-AGL-DemoApps-CES2016 \
	CI-common \
	CI-external-meta-openembedded \
	CI-external-meta-qt5 \
	CI-external-poky \
	CI-meta-agl \
	CI-meta-agl-demo \
	CI-meta-renesas \
	RELEASE-AGL-albacore \
	RELEASE-AGL-albacore-staging \
	; do mkdir -p $d; cd $d; curl -O ${BASE_URL}/$d/jenkins.sh; cd -; done
