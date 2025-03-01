# mb-microservice
# CI/CD con GitHub Actions y Terraform en Azure

Este repositorio contiene una implementación de CI/CD utilizando GitHub Actions, Terraform y Kubernetes en Azure.

## 1. Crear el repositorio en GitHub

Si aún no tienes un repositorio, crea uno en [GitHub](https://github.com/) y clónalo en tu máquina local:

```bash
git clone https://github.com/JulioCesarArbieto/mb-microservice.git
cd mb-microservice
```

## 2. Crear la aplicación en Java

Crea una aplicación simple en Java con Spring Boot:

```bash
curl https://start.spring.io/starter.zip -d dependencies=web -d type=maven-project -d language=java -o mb-microservice.zip
unzip mb-microservice.zip -d mb-microservice
cd mb-microservice
mvn package
```

Edita `src/main/java/com/mibanco/mbmicroservice/HelloController.java` para que devuelva "Hola Mibanco":

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
  subscription_id = "xxxxxx"
  client_id       = "xxxxxx"
  client_secret   = "xxxxxx"
  tenant_id       = "xxxxxx"
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
    node_count = 1
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

# Azure API Management
resource "azurerm_api_management" "apim" {
  name                = "mibanco-apim"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "Mibanco"
  publisher_email     = "admin@mibanco.com"
  sku_name            = "Consumption_0"
}

resource "azurerm_api_management_api" "api" {
  name                = "mibanco-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Mibanco API"
  path                = "mibanco"
  protocols           = ["https"]
  service_url         = "https://${azurerm_api_management.apim.gateway_url}"
}

resource "azurerm_api_management_api_operation" "get_hello" {
  operation_id        = "get-hello"
  api_name            = azurerm_api_management_api.api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Get Hello"
  method              = "GET"
  url_template        = "/"
  response {
    status_code  = 200
    description = "OK"
  }
}

resource "azurerm_api_management_api_policy" "policy" {
  api_name            = azurerm_api_management_api.api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name

  xml_content = <<XML
<policies>
    <inbound>
        <base />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
</policies>
XML
}
```

Inicializa Terraform y aplica los cambios:

```bash
cd infra
terraform init
terraform apply -auto-approve
terraform destroy -auto-approve
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

      #- name: Azure login
      #  uses: azure/login@v2
      #  with:
      #    client-id: ${{ secrets.AZURE_CLIENT_ID }}
      #    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
      #    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
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
  name: mbmicroservice
  labels:
    app: mbmicroservice
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mbmicroservice
  template:
    metadata:
      labels:
        app: mbmicroservice
    spec:
      containers:
      - name: mbmicroservice
        image: mibancoacr.azurecr.io/mbmicroservice:latest # Cambiar según la imagen
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "prod" # Cambiar según el ambiente
```

**Service (`service.yml`)**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mbmicroservice-service
spec:
  selector:
    app: mbmicroservice
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: LoadBalancer # Cambiar a ClusterIP si se usará Ingress
```

**Ingress (`ingress.yml`)**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mbmicroservice-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: mbmicroservice.mibanco.com # Cambiar por el dominio real
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: mbmicroservice-service
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
curl https://${azurerm_api_management.apim.gateway_url}/mibanco
```

Con este flujo, hemos automatizado la infraestructura y el despliegue de la aplicación en Azure. 🚀