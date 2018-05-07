#!/usr/bin/env bash

source "SK/scripts/env.sh";
setperf

# Kernel compiling script

function check_toolchain() {

    export TC="$(find ${TOOLCHAIN}/bin -type f -name *-gcc)";

	if [[ -f "${TC}" ]]; then
		export CROSS_COMPILE="${TOOLCHAIN}/bin/$(echo ${TC} | awk -F '/' '{print $NF'} |\
sed -e 's/gcc//')";
		echo -e "Using toolchain: $(${CROSS_COMPILE}gcc --version | head -1)";
	else
		echo -e "No suitable toolchain found in ${TOOLCHAIN}";
		exit 1;
	fi
}

if [[ -z ${KERNELDIR} ]]; then
    echo -e "Please set KERNELDIR";
    exit 1;
fi

export DEVICE=$1;
if [[ -z ${DEVICE} ]]; then
    export DEVICE="mido";
fi

export SRCDIR="${KERNELDIR}/${DEVICE}";
export OUTDIR="${KERNELDIR}/out";
export ANYKERNEL="${KERNELDIR}/SK/anykernel/";
export ARCH="arm64";
export SUBARCH="arm64";
export TOOLCHAIN="${HOME}/LINARO/7.x";
export DEFCONFIG="strakz_defconfig";
export ZIP_DIR="${KERNELDIR}/SK/files/";
export IMAGE="${OUTDIR}/arch/${ARCH}/boot/Image.gz-dtb";
export VERSION="🐼😂";
export KBUILD_BUILD_USER="ReVaNtH";
export KBUILD_BUILD_HOST="StRaKz";

if [[ -z "${JOBS}" ]]; then
    export JOBS="32";
fi

export MAKE="make O=${OUTDIR}";
check_toolchain;

export TCVERSION1="$(${CROSS_COMPILE}gcc --version | head -1 |\
awk -F '(' '{print $2}' | awk '{print tolower($1)}')"
export TCVERSION2="$(${CROSS_COMPILE}gcc --version | head -1 |\
awk -F ')' '{print $2}' | awk '{print tolower($1)}')"
export ZIPNAME="StRaKz_KeRnEl-${TCVERSION1}.${TCVERSION2}-${DEVICE}-$(date +%Y%m%d-%H%M).zip"
export FINAL_ZIP="${ZIP_DIR}/${ZIPNAME}"

export CROSS_COMPILE="${TOOLCHAIN}/bin/aarch64-opt-linux-android-"

[ ! -d "${ZIP_DIR}" ] && mkdir -pv ${ZIP_DIR}
[ ! -d "${OUTDIR}" ] && mkdir -pv ${OUTDIR}

cd "${SRCDIR}";
rm -fv ${IMAGE};

# if [[ "$@" =~ "mrproper" ]]; then
    ${MAKE} mrproper
# fi

# if [[ "$@" =~ "clean" ]]; then
    ${MAKE} clean
# fi

${MAKE} $DEFCONFIG;
START=$(date +"%s");
${MAKE} -j${JOBS};
exitCode="$?";
END=$(date +"%s")
DIFF=$(($END - $START))
echo -e "Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.";


if [[ ! -f "${IMAGE}" ]]; then
    echo -e "Build failed :P";
    exit 1;
else
    echo -e "Build Succesful!";
fi

echo -e "Copying kernel image";
cp -v "${IMAGE}" "${ANYKERNEL}/";
cd -;
cd ${ANYKERNEL};
zip -r9 ${FINAL_ZIP} *;
cd -;

if [ -f "$FINAL_ZIP" ];
then
echo -e "$ZIPNAME zip can be found at $FINAL_ZIP";
echo -e "Uploading ${ZIPNAME} to https://transfer.sh/";
transfer "${FINAL_ZIP}";
else
echo -e "Zip Creation Failed =(";
fi # FINAL_ZIP check 
