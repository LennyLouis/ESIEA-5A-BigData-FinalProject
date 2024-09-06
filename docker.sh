#!/bin/bash

LOGFILE="./logs/docker.log"

# Function to log messages with timestamp
log_message() {
  # Check if the log folder exists
  if [ ! -d "$(pwd)/logs" ]; then
    mkdir -p "$(pwd)/logs"
  fi

  # shellcheck disable=SC2155
  local log_entry="[$(date +"%Y-%m-%d %H:%M:%S")] $1"

  echo "$log_entry" | tee -a $LOGFILE
}

start() {
    log_message "Starting Hadoop cluster..."

    log_message "Pulling Docker image..."
    docker pull madjidtaoualit/hadoop-cluster:latest >> $LOGFILE 2>&1

    log_message "Creating Docker network..."
    docker network create --driver=bridge hadoop >> $LOGFILE 2>&1

    # Check if the operating system is macOS with Apple Silicon
    if [[ "$(uname -m)" == "arm64" ]]; then
        log_message "macOS with Apple Silicon detected."
        docker run -itd --net=hadoop -p 9870:9870 -p 8088:8088 -p 7077:7077 -p 16010:16010 --name hadoop-master --hostname hadoop-master --platform linux/amd64 madjidtaoualit/hadoop-cluster:latest >> $LOGFILE 2>&1
        docker run -itd -p 8040:8042 --net=hadoop --name hadoop-worker1 --hostname hadoop-worker1 --platform linux/amd64 madjidtaoualit/hadoop-cluster:latest >> $LOGFILE 2>&1
        docker run -itd -p 8041:8042 --net=hadoop --name hadoop-worker2 --hostname hadoop-worker2 --platform linux/amd64 madjidtaoualit/hadoop-cluster:latest >> $LOGFILE 2>&1
    else
        log_message "macOS with Apple Silicon not detected."
        docker run -itd --net=hadoop -p 9870:9870 -p 8088:8088 -p 7077:7077 -p 16010:16010 --name hadoop-master --hostname hadoop-master >> $LOGFILE 2>&1
        docker run -itd -p 8040:8042 --net=hadoop --name hadoop-worker1 --hostname hadoop-worker1 >> $LOGFILE 2>&1
        docker run -itd -p 8041:8042 --net=hadoop --name hadoop-worker2 --hostname hadoop-worker2 >> $LOGFILE 2>&1
    fi

    if [ $? -eq 0 ]; then
        log_message "Hadoop cluster started successfully."
    else
        log_message "Error starting Hadoop cluster. Check the log file for details."
    fi
}

stop() {
    log_message "Stopping Hadoop cluster..."

    log_message "Stopping containers..."
    docker stop hadoop-master hadoop-worker1 hadoop-worker2 >> $LOGFILE 2>&1

    log_message "Removing containers..."
    docker rm hadoop-master hadoop-worker1 hadoop-worker2 >> $LOGFILE 2>&1

    log_message "Removing Docker network..."
    docker network rm hadoop >> $LOGFILE 2>&1

    if [ $? -eq 0 ]; then
        log_message "Hadoop cluster stopped successfully."
    else
        log_message "Error stopping Hadoop cluster. Check the log file for details."
    fi
}

restart() {
    stop
    start
}

login() {
    clear
    log_message "Logging into Hadoop master container..."
    docker exec -it hadoop-master bash
}

deploy() {
    start
    log_message "Deploying Java & Frontend..."

    cd java
    mvn clean package
    log_message "Copying JAR file to container..."
    docker cp target/*.jar hadoop-master:/root/wordcount-spark.jar >> $LOGFILE 2>&1

    if [ $? -eq 0 ]; then
        log_message "Deployment successful."
    else
        log_message "Error during deployment. Check the log file for details."
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    login)
        login
        ;;
    deploy)
        deploy
        ;;
    *)
        log_message "Usage: $0 {start|stop|restart|login|deploy}"
        exit 1
        ;;
esac