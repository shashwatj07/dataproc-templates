#!/usr/bin/env bash
set -e
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#Initialize functions and Constants
BIN_DIR="$(dirname "$BASH_SOURCE")"
PROJECT_ROOT_DIR=${BIN_DIR}/..

PACKAGE_EGG_FILE=dist/dataproc_templates_distribution.egg

. ${BIN_DIR}/dataproc_template_functions.sh

check_required_envvar GCP_PROJECT
check_required_envvar REGION
check_required_envvar GCS_STAGING_LOCATION

python3 ${PROJECT_ROOT_DIR}/setup.py bdist_egg --output=$PACKAGE_EGG_FILE

OPT_PROJECT="--project=${GCP_PROJECT}"
OPT_REGION="--region=${REGION}"
OPT_JARS="--jars=file:///usr/lib/spark/external/spark-avro.jar"
OPT_LABELS="--labels=job_type=dataproc_template"
OPT_DEPS_BUCKET="--deps-bucket=${GCS_STAGING_LOCATION}"
OPT_PY_FILES="--py-files=${PROJECT_ROOT_DIR}/${PACKAGE_EGG_FILE}"

# Optional arguments
if [ -n "${SUBNET}" ]; then
  OPT_SUBNET="--subnet=${SUBNET}"
fi
if [ -n "${HISTORY_SERVER_CLUSTER}" ]; then
  OPT_HISTORY_SERVER_CLUSTER="--history-server-cluster=${HISTORY_SERVER_CLUSTER}"
fi
if [ -n "${METASTORE_SERVICE}" ]; then
  OPT_METASTORE_SERVICE="--metastore-service=${METASTORE_SERVICE}"
fi
if [ -n "${JARS}" ]; then
  OPT_JARS="${OPT_JARS},${JARS}"
fi
if [ -n "${FILES}" ]; then
  OPT_FILES="--files=${FILES}"
fi
if [ -n "${PY_FILES}" ]; then
  OPT_FILES="${OPT_PY_FILES},${PY_FILES}"
fi

if [[ "$3" == *"HIVETOBIGQUERY"* ]]; then
  command=$(cat << EOF
  gcloud beta dataproc batches submit pyspark \
              /home/shubu/dataproc-templates/python/dataproc_templates/hive/gettablelist.py \
              ${OPT_PROJECT} \
              ${OPT_REGION} \
              ${OPT_JARS} \
              ${OPT_LABELS} \
              ${OPT_DEPS_BUCKET} \
              ${OPT_FILES} \
              ${OPT_PY_FILES} \
              ${OPT_PROPERTIES} \
              ${OPT_SUBNET} \
              ${OPT_HISTORY_SERVER_CLUSTER} \
              ${OPT_METASTORE_SERVICE}
EOF
)

echo "Triggering Spark Submit job to get table list"
echo ${command} "$@"
#${command} "$@"
job_status=$?
bucket_id=$(echo ${OPT_DEPS_BUCKET} | cut -d "=" -f 2)
dir=$(echo $4 | cut -d "=" -f 2)
table_list_path=$bucket_id"/"$dir"/*.csv"
tablesfile="tablesfile_"$dir"_"$(date +%s)".log"
echo $tablesfile
gsutil cp $table_list_path tablesfile
log_path=$bucket_id"/"$dir"/"

command=$(cat << EOF
gcloud beta dataproc batches submit pyspark \
    ${PROJECT_ROOT_DIR}/main.py \
    ${OPT_PROJECT} \
    ${OPT_REGION} \
    ${OPT_JARS} \
    ${OPT_LABELS} \
    ${OPT_DEPS_BUCKET} \
    ${OPT_FILES} \
    ${OPT_PY_FILES} \
    ${OPT_PROPERTIES} \
    ${OPT_SUBNET} \
    ${OPT_HISTORY_SERVER_CLUSTER} \
    ${OPT_METASTORE_SERVICE}
EOF
)
command2=$(echo ${command} "$@")

    if [ $job_status == 0 ]
    then
    readarray -t array < tablesfile
    parallel_jobs=2
    arraylen=${#array[@]}
    (( result=(arraylen+parallel_jobs-1)/parallel_jobs ))
    for((i=0; i < $arraylen; i+=result))
    do
    part=( "${array[@]:i:result}" )
    tablearray=("$(IFS=,; echo "${part[*]}")" )
    final_command="${command2} --hive.bigquery.input.table=${tablearray} --properties=spark.dataproc.driver.disk.size=5g	"
    echo ${final_command}
    timestamp=$(date +%s)
    rep_log_path=$timestamp"_$i""_output.log"
    echo $rep_log_path
    ${final_command} > $rep_log_path  2>&1 &
    done
    else
    echo "Could not get table list"
    fi
    # move log files to S3 location check for batch finished line
    #gsutil mv *.log log_path

else
command=$(cat << EOF
gcloud beta dataproc batches submit pyspark \
    ${PROJECT_ROOT_DIR}/main.py \
    ${OPT_PROJECT} \
    ${OPT_REGION} \
    ${OPT_JARS} \
    ${OPT_LABELS} \
    ${OPT_DEPS_BUCKET} \
    ${OPT_FILES} \
    ${OPT_PY_FILES} \
    ${OPT_PROPERTIES} \
    ${OPT_SUBNET} \
    ${OPT_HISTORY_SERVER_CLUSTER} \
    ${OPT_METASTORE_SERVICE}
EOF
)

echo "Triggering Spark Submit job"
echo ${command} "$@"
${command} "$@"
fi