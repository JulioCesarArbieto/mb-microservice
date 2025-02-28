# mb-microservice
# CI/CD con GitHub Actions y Terraform en Azure

Este repositorio contiene una implementación de CI/CD utilizando GitHub Actions, Terraform y Kubernetes en Azure.

## 1. Crear el repositorio en GitHub

Si aún no tienes un repositorio, crea uno en [GitHub](https://github.com/) y clónalo en tu máquina local:

```bash
git clone https://github.com/tu-usuario/tu-repo.git
cd tu-repo
```

## 2. Crear la aplicación en Java

Crea una aplicación simple en Java con Spring Boot:

```bash
curl https://start.spring.io/starter.zip -d dependencies=web -d type=maven-project -d language=java -o app.zip
unzip app.zip -d app
cd app
mvn package
```

Edita `src/main/java/com/example/demo/DemoApplication.java` para que devuelva "Hola Mibanco":

```java
@RestController
public class HelloController {
    @GetMapping("/")
    public String hello() {
        return "Hola Mibanco";
    }
}
```

## 3. Configurar Terraform para la infraestructura en Azure

Crea un directorio `infra` y dentro, el archivo `main.tf` con la configuración de AKS, ACR e Ingress:

```terraform
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "mibanco-rg"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "mibanco-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "mibancoaks"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_container_registry" "acr" {
  name                = "mibancoacr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}
```

Inicializa Terraform y aplica los cambios:

```bash
cd infra
terraform init
terraform apply -auto-approve
```

## 4. Configurar GitHub Actions para CI/CD

Crea el archivo `.github/workflows/ci-cd.yml`:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout código
        uses: actions/checkout@v3
      
      - name: Configurar JDK
        uses: actions/setup-java@v3
        with:
          distribution: 'temurin'
          java-version: '17'
      
      - name: Compilar la aplicación
        run: mvn clean package
      
      - name: Ejecutar pruebas
        run: mvn test
  
  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Checkout código
        uses: actions/checkout@v3
      
      - name: Login en Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Construcción y push de imagen a ACR
        run: |
          az acr login --name mibancoacr
          docker build -t mibancoacr.azurecr.io/mibanco-app:latest .
          docker push mibancoacr.azurecr.io/mibanco-app:latest
      
      - name: Desplegar en AKS
        run: |
          az aks get-credentials --resource-group mibanco-rg --name mibanco-aks
          kubectl apply -f k8s/
```

## 5. Crear manifiestos de Kubernetes (`k8s/`)

Crea los siguientes archivos dentro de `k8s/`:

**Deployment (`deployment.yml`)**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mibanco-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mibanco-app
  template:
    metadata:
      labels:
        app: mibanco-app
    spec:
      containers:
      - name: mibanco-app
        image: mibancoacr.azurecr.io/mibanco-app:latest
        ports:
        - containerPort: 8080
```

**Service (`service.yml`)**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mibanco-service
spec:
  selector:
    app: mibanco-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: LoadBalancer
```

**Ingress (`ingress.yml`)**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mibanco-ingress
spec:
  rules:
    - host: mibanco.local
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: mibanco-service
              port:
                number: 80
```

## 6. Validación del despliegue

Ejecuta:

```bash
kubectl get pods
kubectl get ingress
```

Prueba la aplicación con Postman o `curl`:

```bash
curl http://mibanco.local
```

Con este flujo, hemos automatizado la infraestructura y el despliegue de la aplicación en Azure. 🚀