# Usa una imagen ligera de OpenJDK 17
FROM openjdk:17-jdk-slim
# Establece el directorio de trabajo dentro del contenedor
WORKDIR /app
# Copia el JAR generado en la carpeta target al contenedor
COPY target/mbmicroservice-0.0.1-SNAPSHOT.jar app.jar
# Expone el puerto en el que corre la aplicación
EXPOSE 8080
# Comando para ejecutar la aplicación
CMD ["java", "-jar", "app.jar"]

## Utiliza una imagen base de OpenJDK 17
#FROM openjdk:17-jdk-slim
## Establece el directorio de trabajo en /app
#WORKDIR /app
## Copia el archivo JAR generado por Maven al contenedor
#COPY target/mbmicroservice-0.0.1-SNAPSHOT.jar app.jar
# Expone el puerto 8080 para acceder a la aplicación
#EXPOSE 8080
## Comando para ejecutar la aplicación cuando el contenedor se inicia
#CMD ["java", "-jar", "app.jar"]
