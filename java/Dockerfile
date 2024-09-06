# Utilise une image de base pour Maven et Java
FROM maven:3.8.5-openjdk-17 AS build

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers pom.xml et télécharger les dépendances
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copier tout le code source et construire le projet
COPY src /app/src
RUN mvn package -DskipTests

# Créer un dossier pour le build
RUN mkdir /build

# Copier le jar généré dans le dossier build
RUN cp target/*.jar /build/
