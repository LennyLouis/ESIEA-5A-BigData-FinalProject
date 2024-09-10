#!/bin/bash

LOGFILE="/root/logs/run-spark-jobs.log"

log_message() {
  local log_entry="[$(date +"%Y-%m-%d %H:%M:%S")] $1"
  printf "%s\n" "$log_entry" | tee -a $LOGFILE
}

# Clean HDFS folders
clean_folders() {
  log_message "Cleaning HDFS folders..."
  hdfs dfs -rm -r -skipTrash /user/root/output
  hdfs dfs -rm -skipTrash /user/root/dataset.csv
  hdfs dfs -rm -skipTrash /user/root/finalproject.jar
}

# Create HDFS directories
create_hdfs_directories() {
  log_message "Creating HDFS directories..."
  hdfs dfs -mkdir -p /user/root/output
  hdfs dfs -chmod -R 777 /user/root
}

# Copy dataset to HDFS
copy_dataset() {
  log_message "Copying dataset to HDFS..."
  hdfs dfs -put /root/dataset.csv /user/root/dataset.csv
}

# Run Spark jobs
run_spark_job() {
  local class_name=$1
  log_message "Running Spark job: $class_name"
  spark-submit --class fr.esiea.bigdata.spark.bike.$class_name --master yarn --deploy-mode cluster /root/finalproject.jar dataset.csv output/$class_name
}

run_spark_jobs() {
  log_message "Running all Spark jobs..."
  run_spark_job "BikeAverageByDayOfTheWeekHoliday"
  run_spark_job "BikeAverageByDayOfTheWeekSeason"
  run_spark_job "BikeAverageMonthWeekendOrNot"
  run_spark_job "BikeCountPerHour"
  run_spark_job "BikeCountPerHourAndTemp"
  run_spark_job "BikeCountPerHourAndWind"
}

# Copy Spark output to local filesystem
copy_spark_output() {
  log_message "Copying Spark output to local filesystem..."
  hdfs dfs -get /user/root/output /root/
}

# Main process
log_message "Starting Spark job execution process..."
clean_folders
create_hdfs_directories
copy_dataset
run_spark_jobs
copy_spark_output
log_message "Spark job execution completed."