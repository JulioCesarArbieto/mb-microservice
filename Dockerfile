# Usa una imagen ligera de OpenJDK 17
FROM openjdk:17-alpine 
#FROM openjdk:17-jdk-slim
WORKDIR /app
COPY target/mbmicroservice-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
# Comando para ejecutar la aplicación
CMD ["java", "-jar", "app.jar"]

#FROM openjdk:17-alpine 
#ENV TZ='America/Lima'
#RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
#WORKDIR /app
#COPY target/mbmicroservice-0.0.1-SNAPSHOT.jar  /app
#EXPOSE 8080
#CMD ["java","-jar","mbmicroservice-0.0.1-SNAPSHOT.jar"]
