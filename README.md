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

Crea un directorio `infra` y dentro, los siguientes archivos:

### `infra/main.tf`

```terraform
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "mibanco-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "mibanco"

  default_node_pool {
    name       = "default"
    node_count = var.aks_node_count
    vm_size    = var.aks_vm_size
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
}

resource "azurerm_api_management" "apim" {
  name                = "mibanco-apim"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "Mibanco"
  publisher_email     = "contacto@mibanco.com"
  sku_name            = "Developer"
}
```

### `infra/variables.tf`

```terraform
variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "client_id" {
  description = "Azure Client ID"
  type        = string
}

variable "client_secret" {
  description = "Azure Client Secret"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
  type        = string
  default     = "mibanco-rg"
}

variable "location" {
  description = "Ubicación de los recursos en Azure"
  type        = string
  default     = "East US"
}

variable "aks_node_count" {
  description = "Cantidad de nodos en AKS"
  type        = number
  default     = 1
}

variable "aks_vm_size" {
  description = "Tamaño de la VM en AKS"
  type        = string
  default     = "Standard_B2s"
}
```

### `infra/terraform.tfvars`

```terraform
subscription_id = "tu-subscription-id"
client_id       = "tu-client-id"
client_secret   = "tu-client-secret"
tenant_id       = "tu-tenant-id"
location        = "East US"
```

Inicializa Terraform y aplica los cambios:

```bash
cd infra
terraform init
terraform plan
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

      - name: Construir aplicación con Maven
        run: |
          mvn clean package -DskipTests

      - name: Verificar que el JAR fue generado
        run: |
          ls -l target/

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
      
      - name: Construir y subir imagen a ACR
        run: |
          az acr login --name mibancoacr
          docker build -t mibancoacr.azurecr.io/mibanco:latest .
          docker push mibancoacr.azurecr.io/mibanco:latest

      - name: Desplegar en AKS
        run: |
          az aks get-credentials --resource-group mibanco-rg --name mibanco-aks
          kubectl apply -f k8s/

      - name: Desplegar en AKS
        run: |
          az aks get-credentials --resource-group mibanco-rg --name mibanco-aks
          kubectl get namespaces
          kubectl get pods
          kubectl get services
          kubectl get deployments
          kubectl get replicasets
          kubectl get events
          kubectl get all

      #- name: Registrar API en API Management
      #  run: |
      #    az apim api import --resource-group mibanco-rg --service-name mibanco-apim --path "mibanco" --api-id "mibanco-api" --wsdl-url "http://mibanco.local/swagger.yaml"
```

## 5. Crear manifiestos de Kubernetes (`k8s/`)

Crea los siguientes archivos dentro de `k8s/`:

**Deployment (`deployment.yml`)**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mibanco-app
  labels:
    app: mibanco
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mibanco
  template:
    metadata:
      labels:
        app: mibanco
    spec:
      containers:
        - name: mibanco-app
          image: mibancoacr.azurecr.io/mibanco:latest
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
    app: mibanco
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: LoadBalancer # Cambiar a ClusterIP 

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
  kubectl get namespaces
  kubectl get pods
  kubectl get ingress
  kubectl get services
  kubectl get deployments
  kubectl get replicasets
  kubectl get events
  kubectl get all
```

Prueba la aplicación con Postman o `curl`:

```bash
curl https://${azurerm_api_management.apim.gateway_url}/mibanco
```

Con este flujo, hemos automatizado la infraestructura y el despliegue de la aplicación en Azure. 🚀