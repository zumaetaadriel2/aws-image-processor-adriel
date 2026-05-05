# aws-image-processor-adriel

# AWS Image Processor - Infraestructura como Código (IaC)

Este proyecto implementa una arquitectura Serverless y orientada a eventos en AWS para el procesamiento automático de imágenes. El sistema permite cargar imágenes a través de una API, las almacena en S3, las encola en SQS y utiliza funciones Lambda para redimensionarlas y aplicar un recorte circular.

## 📊 Arquitectura del Sistema

El diseño y la implementación de este código siguen estrictamente el diagrama de arquitectura adjunto en el archivo `mermaid.md`. 

**Componentes clave:**
* **API Gateway:** Punto de entrada para la carga de imágenes.
* **Amazon S3:** Almacenamiento persistente para imágenes originales (`uploads/`) y procesadas (`processed/`).
* **Amazon SQS:** Cola de mensajes para desacoplar la carga de la imagen del procesamiento.
* **AWS Lambda:** Funciones serverless para la lógica de carga y procesamiento (Node.js + Sharp).
* **VPC & Networking:** Aislamiento de recursos en subredes privadas con NAT Gateways para salida segura a internet.

## 🚀 Despliegue en Múltiples Entornos

La arquitectura está diseñada para ser desplegada en tres entornos aislados utilizando **Terraform Workspaces** y archivos de variables específicos (`.tfvars`):

1.  **DEV (Desarrollo):** Para pruebas iniciales y desarrollo activo.
2.  **QA (Quality Assurance):** Para pruebas de calidad y validación de integraciones.
3.  **PROD (Producción):** Entorno final estable para usuarios finales.

### Requisitos Previos
* Terraform >= 1.0.0
* AWS CLI configurado con credenciales válidas.
* Node.js instalado (para la compilación de funciones Lambda).

### Pasos para el Despliegue

Siga estos pasos para desplegar en cualquiera de los entornos (ejemplo para `dev`):

1.  **Inicializar Terraform:**
    ```bash
    cd iac/
    terraform init
    ```

2.  **Seleccionar o Crear el Workspace:**
    ```bash
    # Crear workspace si no existe
    terraform workspace new dev 
    # O seleccionar si ya existe
    terraform workspace select dev
    ```

3.  **Ejecutar Plan de Ejecución:**
    ```bash
    terraform plan -var-file="envs/dev.tfvars"
    ```

4.  **Aplicar Cambios:**
    ```bash
    terraform apply -var-file="envs/dev.tfvars" -auto-approve
    ```

## 🧪 Pruebas de la API

Una vez desplegado, Terraform devolverá un `api_endpoint`. Puede probar la carga de una imagen usando `curl`:

```bash
curl -X POST <API_ENDPOINT_URL> \
  -H "Content-Type: image/png" \
  --data-binary "@tu_foto.png"
```

## 🛡️ Buenas Prácticas: Control de Costos y Limpieza

Una de las prácticas fundamentales en la Gestión de Infraestructura Cloud es el **ciclo de vida de recursos**. Mantener recursos activos sin uso genera costos innecesarios (especialmente NAT Gateways y VPC Endpoints).

### Protocolo de Destrucción (Recomendado)

Se ha establecido como regla de oro ejecutar la destrucción total de la infraestructura al finalizar las pruebas o validaciones en cada entorno.

**Pasos críticos antes de destruir:**
1. **Vaciar el Almacenamiento:** Entre a la consola de AWS -> S3 y vacíe el bucket `adriel-img-proc-*-images-zumaeta`. Terraform no puede eliminar buckets que contengan objetos.
2. **Cierre de Sesiones:** Asegúrese de que no haya túneles o conexiones activas a la red.

**Comando de limpieza total:**
```bash
# Regresar a la carpeta de infraestructura
cd iac/

# Seleccionar el entorno deseado
terraform workspace select <entorno>

# Ejecutar la destrucción automatizada
terraform destroy -var-file="envs/<entorno>.tfvars" -auto-approve ´