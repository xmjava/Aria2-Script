#!/usr/bin/env bash
#
# File name：smartbt.sh
# Description: Smart select bt movie files after Aria2 download is start
# Version: 1.0
#
# Modify from https://github.com/P3TERX/aria2.conf by suzh
#

CHECK_CORE_FILE() {
    CORE_FILE="$(dirname $0)/core"
    if [[ -f "${CORE_FILE}" ]]; then
        . "${CORE_FILE}"
    else
        echo "!!! core file does not exist !!!"
        exit 1
    fi
}

#Smart select bt files after Aria2 download is start by suzh
SMART_SELECT_FILES() {
    [[ -z ${RPC_RESULT} ]] && {
        echo -e "$(DATE_TIME) ${ERROR} Aria2 RPC interface error!"
        exit 1
    }

    SHELL_FOLDER=$(dirname $(readlink -f "$0"))"/"

    if [ -f "${SHELL_FOLDER}${TASK_GID}" ]; then
        # echo -e "the task has selected"
        rm ${SHELL_FOLDER}${TASK_GID}
        exit 0
    fi

    if GET_INFO_HASH; then  #is BT task!
        #check task file list and smart select
        DOWNLOAD_FILES=$(echo "${RPC_RESULT}" | jq -r '.result.files')
        # echo -e "${DOWNLOAD_FILES}"
        DOWNLOAD_FILES_COUNT=$(echo "${DOWNLOAD_FILES}" | jq 'length')
        # echo -e "${DOWNLOAD_FILES_COUNT}"
        SELECT_FILES_INDEX=""
        for ((INDEX=0; INDEX<${DOWNLOAD_FILES_COUNT}; INDEX++));
        do
            DOWNLOAD_FILE=$(echo "${DOWNLOAD_FILES}" | jq -r '.['${INDEX}'].path')
            # echo -e "${DOWNLOAD_FILE}"
            DOWNLOAD_FILE_LENGTH=$(echo "${DOWNLOAD_FILES}" | jq -r '.['${INDEX}'].length')
            # echo -e "${DOWNLOAD_FILE_LENGTH}"
            # echo -e "${BT_MIN_FILE_LENGTH}"
            if [ ${DOWNLOAD_FILE_LENGTH} -gt ${BT_MIN_FILE_LENGTH} ]; then
                # echo -e "${DOWNLOAD_FILE}"
                if [ "${SELECT_FILES_INDEX}" ]; then
                    SELECT_FILES_INDEX=${SELECT_FILES_INDEX}","
                fi
                SELECT_FILES_INDEX=${SELECT_FILES_INDEX}$(($INDEX + 1))
            fi
        done
        # echo -e "${SELECT_FILES_INDEX}"
        #change task option
        if [[ "${RPC_SECRET}" ]]; then
            RPC_PAYLOAD='{"jsonrpc":"2.0","method":"aria2.changeOption","id":"P3TERX","params":["token:'${RPC_SECRET}'","'${TASK_GID}'",{"select-file":"'${SELECT_FILES_INDEX}'"}]}'
        else
            RPC_PAYLOAD='{"jsonrpc":"2.0","method":"aria2.changeOption","id":"P3TERX","params":["'${TASK_GID}'",{"select-file":"'${SELECT_FILES_INDEX}'"}]}'
        fi
        # echo -e "${RPC_PAYLOAD}"
        curl "${RPC_ADDRESS}" -fsSd "${RPC_PAYLOAD}" || curl "https://${RPC_ADDRESS}" -kfsSd "${RPC_PAYLOAD}"

        echo "s" >> ${SHELL_FOLDER}${TASK_GID}
    fi
}

CHECK_CORE_FILE "$@"
CHECK_PARAMETER "$@"
CHECK_FILE_NUM
CHECK_SCRIPT_CONF
GET_TASK_INFO
BT_MIN_FILE_LENGTH=50000000  #only download file length > 50M
SMART_SELECT_FILES
exit 0
