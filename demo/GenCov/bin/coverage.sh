source /opt/boxen/env.sh
COV_PATH=${SRCROOT}/Coverage
COV_INFO=${COV_PATH}/Coverage.info
OBJ_ARCH_PATH=${PROJECT_TEMP_DIR}/${CONFIGURATION}-iphonesimulator/${PROJECT_NAME}.build/Objects-normal/i386

mkdir -p ${COV_PATH}
/usr/bin/env lcov --capture -b ${SRCROOT} -d ${OBJ_ARCH_PATH} -o ${COV_INFO}
/usr/bin/env lcov --remove ${COV_INFO} "/Applications/Xcode.app/*" -d ${OBJ_ARCH_PATH} -o ${COV_INFO}
/usr/bin/env lcov --remove ${COV_INFO} "main.m" -d ${OBJ_ARCH_PATH} -o ${COV_INFO}

/usr/bin/env genhtml --output-directory ${COV_PATH} ${COV_INFO}
