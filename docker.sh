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
        docker run -itd --net=hadoop -p 9870:9870 -p 8088:8088 -p 7077:7077 -p 16010:16010 --name hadoop-master --hostname hadoop-master madjidtaoualit/hadoop-cluster:latest >> $LOGFILE 2>&1
        docker run -itd -p 8040:8042 --net=hadoop --name hadoop-worker1 --hostname hadoop-worker1 madjidtaoualit/hadoop-cluster:latest >> $LOGFILE 2>&1
        docker run -itd -p 8041:8042 --net=hadoop --name hadoop-worker2 --hostname hadoop-worker2 madjidtaoualit/hadoop-cluster:latest >> $LOGFILE 2>&1
    fi

    docker exec -it hadoop-master bash -c "/root/start-hadoop.sh" >> $LOGFILE 2>&1

    if [ $? -eq 0 ]; then
        log_message "Hadoop cluster started successfully."
    else
        error_message "Error starting Hadoop cluster. Check the log file for details."
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
        error_message "Error stopping Hadoop cluster. Check the log file for details."
    fi
}

restart() {
    stop
    start
}

login() {
    clear
    log_message "Logging into Hadoop master container..."
    echo "Don't forget to start the Hadoop cluster by executing the following command:"
    echo " "
    echo "   ./start-hadoop.sh"
    echo " "
    docker exec -it hadoop-master bash
}

deploy() {
    start
    log_message "Deploying Java & Frontend..."

    # Se déplacer dans le répertoire java
    cd java || (error_message "Error changing directory to java. Check the log file for details. Exit." && exit 1)

    # Forcer le rebuild en invalidant le cache à chaque build
    log_message "Building Docker image..."
    docker build --no-cache -t spark-compiler . >> $LOGFILE 2>&1
    if [ $? -ne 0 ]; then
        error_message "Error during Docker build. Check the log file for details."
        exit 1
    fi

    cd ..

    # Créer le répertoire output s'il n'existe pas
    mkdir -p output

    log_message "Running Docker container..."
    # Monter un volume pour récupérer les fichiers de sortie depuis /app/output dans le conteneur
    docker run --rm -v $(pwd)/output:/app/output spark-compiler >> $LOGFILE 2>&1
    if [ $? -ne 0 ]; then
        error_message "Error during Docker run. Check the log file for details."
        exit 1
    fi

    log_message "Cleaning up the container..."
    docker exec -it hadoop-master bash -c "rm -f /root/dataset.csv" >> $LOGFILE 2>&1
    docker exec -it hadoop-master bash -c "rm -f /root/finalproject.jar" >> $LOGFILE 2>&1
    if [ $? -ne 0 ]; then
        error_message "Error during cleanup. Check the log file for details."
        exit 1
    fi

    log_message "Copying JAR and dataset files to container..."
    docker cp output/*.jar hadoop-master:/root/finalproject.jar >> $LOGFILE 2>&1
    docker cp java/src/main/resources/dataset/london_merged.csv hadoop-master:/root/dataset.csv >> $LOGFILE 2>&1
    if [ $? -ne 0 ]; then
        error_message "Error during file copying. Check the log file for details."
        exit 1
    fi

    log_message "Deployment successful."
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