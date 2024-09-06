#!/bin/bash

LOGFILE="./logs/reduce-data.log"

# Function to log messages with timestamp
log_message() {
  # Check if the log folder exists
  if [ ! -d "$(pwd)/logs" ]; then
    mkdir -p "$(pwd)/logs"
  fi

  # shellcheck disable=SC2155
  local log_entry="[$(date +"%Y-%m-%d %H:%M:%S")] $1"

  # Use printf to ensure correct formatting and append to the log file
  printf "%s\n" "$log_entry" | tee -a $LOGFILE
}

# Function to print error messages in red
error_message() {
  # Check if the log folder exists
  if [ ! -d "$(pwd)/logs" ]; then
    mkdir -p "$(pwd)/logs"
  fi

  # shellcheck disable=SC2155
  local log_entry="[$(date +"%Y-%m-%d %H:%M:%S")] $1"

  # Print the error message in red to the terminal and append to the log file
  printf "\033[0;31m%s\033[0m\n" "$log_entry" | tee -a $LOGFILE
}

clean_folders(){
  log_message "Cleaning folders..."

  # Remove the output folder from HDFS, ignore errors if the directory doesn't exist
  docker exec -it hadoop-master bash -c "hdfs dfs -rm -r -skipTrash /user/root/output" >> $LOGFILE 2>&1

  # Remove the dataset and JAR file from HDFS, ignore errors if they don't exist
  docker exec -it hadoop-master bash -c "hdfs dfs -rm -skipTrash /user/root/dataset.csv" >> $LOGFILE 2>&1
  docker exec -it hadoop-master bash -c "hdfs dfs -rm -skipTrash /user/root/finalproject.jar" >> $LOGFILE 2>&1

  if [ $? -eq 0 ]; then
    log_message "Folders cleaned successfully."
  else
    error_message "Error cleaning folders. Check the log file for details."
  fi
}

create_hdfs_directories() {
  log_message "Creating HDFS directories..."

  # Create HDFS directories
  docker exec -it hadoop-master bash -c "hdfs dfs -mkdir -p /user/root/output" >> $LOGFILE 2>&1
  docker exec -it hadoop-master bash -c "hdfs dfs -chmod -R 777 /user/root" >> $LOGFILE 2>&1

  if [ $? -eq 0 ]; then
    log_message "HDFS directories created successfully."
  else
    error_message "Error creating HDFS directories. Check the log file for details."
  fi
}

copy_dataset() {
  log_message "Copying dataset to HDFS..."

  # Copy the dataset to HDFS
  docker exec -it hadoop-master bash -c "hdfs dfs -put /root/dataset.csv /user/root/dataset.csv" >> $LOGFILE 2>&1

  if [ $? -eq 0 ]; then
    log_message "Dataset copied to HDFS successfully."
  else
    error_message "Error copying dataset to HDFS. Check the log file for details."
  fi
}

run_spark_job() {
  local class_name=$1
  log_message "Running Spark job $class_name..."

  # Run the Spark job
  docker exec -it hadoop-master bash -c "spark-submit --class fr.esiea.bigdata.spark.bike.$class_name --master yarn --deploy-mode cluster /root/finalproject.jar dataset.csv output/$class_name" >> $LOGFILE 2>&1

  if [ $? -eq 0 ]; then
    log_message "Spark job $class_name completed successfully."
  else
    error_message "Error running Spark job $class_name. Check the log file for details."
    error_message "Exiting reduce-data.sh script."
    exit 1
  fi
}

run_spark_jobs() {
  log_message "Running Spark jobs..."

  # Run the Spark jobs
  run_spark_job "BikeAverageByDayOfTheWeekHoliday"
  run_spark_job "BikeAverageByDayOfTheWeekSeason"
  run_spark_job "BikeAverageMonthWeekendOrNot"
  run_spark_job "BikeCountPerHour"
  run_spark_job "BikeCountPerHourAndTemp"
  run_spark_job "BikeCountPerHourAndWind"

  if [ $? -eq 0 ]; then
    log_message "All Spark jobs completed successfully."
  else
    error_message "Error running all Spark jobs. Check the log file for details."
  fi
}

./docker.sh stop

./docker.sh deploy

log_message "Reducing data..."

clean_folders

  # Create HDFS directories
create_hdfs_directories

# Copy the dataset to HDFS
copy_dataset

# Run the Spark jobs
run_spark_jobs