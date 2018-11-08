#!/bin/bash

#This script sets up the environment to create a raspberry-pi image that contains the meta-ivi layer
#See https://github.com/GENIVI/meta-ivi/tree/14.x-sumo for the currently recommended revisions and branches 

###############################Set Variables################################

GREEN='\033[0;32m'
NC='\033[0m' # No Color

poky_branch="sumo"
poky_url="git://git.yoctoproject.org/poky"
poky_revision="d240b885f26e9b05c8db0364ab2ace9796709aad"

oe_branch="sumo"
oe_url="git://git.openembedded.org/meta-openembedded"
oe_revision="2bb21ef27c4b0c9d52d30b3b2c5a0160fd02b966"

gplv2_branch="sumo"
gplv2_url="git://git.yoctoproject.org/meta-gplv2"
gplv2_revision="d7687d404bbc9ba3f44ec43ea8828d9071033513"

rpi_branch="sumo"
rpi_url="https://github.com/agherzan/meta-raspberrypi.git"
rpi_revision="sumo"

meta_ivi_branch="master"
meta_ivi_url="https://github.com/GENIVI/meta-ivi.git"
meta_ivi_revision="14.x-sumo"

startup_dir=${PWD}
build_dir=${startup_dir}/build-meta-ivi

#################################Clone Repos##################################

if [ ! -d  ${startup_dir}/meta-raspberrypi ]
then
	echo -e "${GREEN}Cloning raspberrypi...${NC}\n\n"
	git clone ${rpi_url} -b ${rpi_branch} ${startup_dir}/meta-raspberrypi
	cd ${startup_dir}/meta-raspberrypi
	git checkout ${rpi_revision}
else
	echo -e "${GREEN}Repository for raspberrypi already exists.${NC}"
fi

if [ ! -d  ${startup_dir}/meta-gplv2 ]
then
	echo -e "\n\n${GREEN}Cloning gplv2...${NC}\n\n"
	git clone ${gplv2_url} -b ${gplv2_branch} ${startup_dir}/meta-gplv2
	cd ${startup_dir}/meta-gplv2 
	git checkout ${gplv2_revision}
else
	echo -e "${GREEN}Repository for gplv2 already exists.${NC}"
fi

cd 

if [ ! -d  ${startup_dir}/meta-openembedded ]
then
	echo -e "\n\n${GREEN}Cloning openembedded...${NC}\n\n"
	git clone ${oe_url} -b ${oe_branch} ${startup_dir}/meta-openembedded
	cd ${startup_dir}/meta-openembedded
	git checkout ${oe_revision}
else
	echo -e "${GREEN}Repository for openembedded already exists.${NC}"
fi

if [ ! -d  ${startup_dir}/meta-ivi ]
then
	echo -e "\n\n${GREEN}Cloning meta-ivi...${NC}"
	git clone ${meta_ivi_url} -b ${meta_ivi_branch} ${startup_dir}/meta-ivi
	cd ${startup_dir}/meta-ivi
	git checkout ${meta_ivi_revision}
else
	echo -e "${GREEN}Repository for meta-ivi already exists.${NC}"
fi


if [ ! -d  ${startup_dir}/poky ]
then
	echo -e "\n\n${GREEN}Cloning poky...${NC}"
	git clone ${poky_url} -b ${poky_branch} ${startup_dir}/poky
	cd ${startup_dir}/poky
	git checkout ${poky_revision}
else
	echo -e "${GREEN}Repository for poky already exists.${NC}"
fi

#################################Init poky##################################
. ${startup_dir}/poky/oe-init-build-env ${build_dir}


##############################Set config files##############################

echo -e "\n${GREEN}Update bblayers.conf${NC}"

cat > ${build_dir}/conf/bblayers.conf << EOL
# POKY_BBLAYERS_CONF_VERSION is increased each time build/conf/bblayers.conf
# changes incompatibly
POKY_BBLAYERS_CONF_VERSION = "2"

BBPATH = "\${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \
${startup_dir}/poky/meta \\
${startup_dir}/poky/meta-poky \\
${startup_dir}/poky/meta-yocto-bsp \\
${startup_dir}/meta-raspberrypi \\
${startup_dir}/meta-openembedded/meta-oe \\
${startup_dir}/meta-openembedded/meta-python \\
${startup_dir}/meta-openembedded/meta-filesystems \\
${startup_dir}//meta-gplv2 \\
${startup_dir}//meta-ivi/meta-ivi \\
${startup_dir}//meta-ivi/meta-ivi-test \\
"
EOL

echo -e "${GREEN}Update local.conf${NC}"

cat > ${build_dir}/conf/local.conf << EOL
#
# This file is your local configuration file and is where all local user settings
# are placed. The comments in this file give some guide to the options a new user
# to the system might want to change but pretty much any configuration option can
# be set in this file. More adventurous users can look at local.conf.extended
# which contains other examples of configuration which can be placed in this file
# but new users likely won't need any of them initially.
#
# Lines starting with the '#' character are commented out and in some cases the
# default values are provided as comments to show people example syntax. Enabling
# the option is a question of removing the # character and making any change to the
# variable as required.

MACHINE = "raspberrypi3"

PREFERRED_VERSION_audiomanagerplugins   ?= "7.0"

DISTRO ?= "poky-ivi-systemd"

PACKAGE_CLASSES ?= "package_rpm"

EXTRA_IMAGE_FEATURES ?= "debug-tweaks"

USER_CLASSES ?= "buildstats image-mklibs image-prelink"

PATCHRESOLVE = "noop"

BB_DISKMON_DIRS ??= "\\
    STOPTASKS,\${TMPDIR},1G,100K \\
    STOPTASKS,\${DL_DIR},1G,100K \\
    STOPTASKS,\${SSTATE_DIR},1G,100K \\
    STOPTASKS,/tmp,100M,100K \\
    ABORT,\${TMPDIR},100M,1K \\
    ABORT,\${DL_DIR},100M,1K \\
    ABORT,\${SSTATE_DIR},100M,1K \\
    ABORT,/tmp,10M,1K"

PACKAGECONFIG_append_pn-qemu-native = " sdl"
PACKAGECONFIG_append_pn-nativesdk-qemu = " sdl"

CONF_VERSION = "1"

DISTRO_FEATURES_append = " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"
DISTRO_FEATURES_BACKFILL_CONSIDERED = "sysvinit"

INCOMPATIBLE_LICENSE ?= "GPLv3"
EOL

echo -e "\n${GREEN}Set up complete: Run 'bitbake test-image'${NC}"


#End
