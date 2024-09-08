# Étape 1 : Utiliser une image de base Java avec Maven
FROM maven:3.8.5-openjdk-11 as build

# Étape 2 : Définir le répertoire de travail dans le conteneur
WORKDIR /app

# Étape 3 : Copier les fichiers du projet dans le conteneur
COPY . /app

# Étape 4 : Compiler le projet Java avec Maven
RUN mvn clean package

# Étape 5 : Créer un répertoire temporaire pour stocker le JAR compilé
RUN mkdir -p /app/output

# Étape 6 : Définir une commande d'exécution pour copier le JAR
ENTRYPOINT [ "bash", "-c", "cp /app/target/*.jar /app/output/" ]