#!/bin/sh
cd logs
GCS_LOCATION=$1
echo "Running Logs Monitor Job"
echo "Exiting here will not stop background Dataproc Jobs"
echo -e "\nWaiting for 10 seconds for the jobs to get started"
sleep 10
echo "Starting Job Monitor Job"
no_of_log_files=$(( $(ls -l|wc -l)-1  ))
echo "Total Number of Dataproc Serverless Jobs Running: "$no_of_log_files
(grep -i "Batch.*submitted." *.log || echo "0 NA") | awk  '{print $2}'
finished_job_count=$(grep -i "Batch.*finished." *.log | wc -l)
submitted_job_count=$(grep -i "Batch.*submitted." *.log | wc -l)
failed_job_count=$(grep -i "Batch.*FAILED." *.log | wc -l)
echo $finished_job_count
echo $submitted_job_count

while [ $submitted_job_count != $(( $finished_job_count+$failed_job_count )) ]
do
    echo -e "\nCompleted Jobs: "
    (grep -i "Batch.*finished." *.log || echo "0 NA") | awk  '{print $2}'
    echo -e "\nBelow tables are Loaded: "
    (grep -i "Table.*loaded" *.log || echo "0 NA") | awk  '{print $2}'
    echo -e "\nRefreshing Logs.."
    sleep 5
    finished_job_count=$(grep -i "Batch.*finished." *.log | wc -l)
    submitted_job_count=$(grep -i "Batch.*submitted." *.log | wc -l)
    failed_job_count=$(grep -i "Batch.*FAILED." *.log | wc -l)
done
echo -e "\nBelow Jobs are Completed: "
(grep -i "Batch.*finished." *.log || echo "0 NA") | awk  '{print $2}'
echo -e "\nBelow tables are Loaded: "
(grep -i "Table.*loaded" *.log || echo "0 NA") | awk  '{print $2}'
echo -e "\nBelow Jobs Failed: "
if [ $failed_job_count > 0 ]
then
    grep -iH "Batch.*submitted." $((grep -iL "Batch.*finished." *.log) | xargs) | awk  '{print $2}'
fi
echo -e "\n"
if [ $submitted_job_count == $(( $finished_job_count+$failed_job_count )) ]
then
  chmod 777 *.log
  gsutil mv *.log $GCS_STAGING_LOCATION/logs
fi
echo "For more information check Dataproc Logs or GCS logs bucket: "$GCS_LOCATION/logs
# In case any log file is left, moving the same to archive folder
mv *.log archive/