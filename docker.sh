#!/bin/bash

start() {
    echo "Starting Hadoop cluster..."
    echo " "
    docker pull madjidtaoualit/hadoop-cluster:latest
    docker network create --driver=bridge hadoop

    # Check if the operating system is macOS with Apple Silicon
    if [[ "$(uname -m)" == "arm64" ]]; then
        echo "macOS with Apple Silicon detected."
        docker run -itd --net=hadoop -p 9870:9870 -p 8088:8088 -p 7077:7077 -p 16010:16010 --name hadoop-master --hostname hadoop-master --platform linux/amd64 madjidtaoualit/hadoop-cluster:latest
        docker run -itd -p 8040:8042 --net=hadoop --name hadoop-worker1 --hostname hadoop-worker1 --platform linux/amd64 madjidtaoualit/hadoop-cluster:latest
        docker run -itd -p 8041:8042 --net=hadoop --name hadoop-worker2 --hostname hadoop-worker2 --platform linux/amd64 madjidtaoualit/hadoop-cluster:latest
    else
        echo "macOS with Apple Silicon not detected."
        docker run -itd --net=hadoop -p 9870:9870 -p 8088:8088 -p 7077:7077 -p 16010:16010 --name hadoop-master --hostname hadoop-master
        docker run -itd -p 8040:8042 --net=hadoop --name hadoop-worker1 --hostname hadoop-worker1
        docker run -itd -p 8041:8042 --net=hadoop --name hadoop-worker2 --hostname hadoop-worker2
    fi
}

stop() {
    echo "Stopping Hadoop cluster..."
    echo " "
    docker stop hadoop-master hadoop-worker1 hadoop-worker2
    docker rm hadoop-master hadoop-worker1 hadoop-worker2
    docker network rm hadoop
}

restart() {
    stop
    start
}

login() {
    clear
    echo "Logging into Hadoop master container..."
    echo " "
    docker exec -it hadoop-master bash
}

deploy() {
    start
    echo "Deploying Java & Frontend..."
    echo " "
    
    cd java
    mvn clean package
    docker cp target/*.jar hadoop-master:/root/wordcount-spark.jar
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
        echo "Usage: $0 {start|stop|restart|login}"
        exit 1
        ;;
esac