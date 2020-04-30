#!/bin/bash

set -eo pipefail

# current directory of this script
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
DATA_DIR=${SOURCE_DIR}/..

WDL=${DATA_DIR}/joint-discovery-gatk4.wdl
INPUTS=${DATA_DIR}/joint-discovery-gatk4.hg38.wgs.inputs.json
OPTIONS=${DATA_DIR}/2019.06.14.options.json

#echo "WDL=${WDL}"
#echo "INPUTS=${INPUTS}"
#echo "OPTIONS=${OPTIONS}"

set -o xtrace

curl -v "localhost:8000/api/workflows/v1" -F workflowSource=@${WDL} -F workflowInputs=@${INPUTS} -F workflowOptions=@${OPTIONS} 

set +o xtrace

# bash bin/submit-workflow.sh 2>&1 | tee logs/client/submit-job.log.$(date "+%Y.%m.%d.%H.%M")
