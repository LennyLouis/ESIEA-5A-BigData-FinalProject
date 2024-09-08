# Étape 1 : Utiliser une image de base Java
FROM maven:3.8.5-openjdk-11 as build

# Étape 2 : Définir le répertoire de travail dans le conteneur
WORKDIR /app

# Étape 3 : Copier les fichiers du projet dans le conteneur
COPY . /app

# Étape 4 : Compiler le projet Java avec Maven
RUN mvn clean package