# Scarlatti-Gest

Este proyecto es una aplicación web desarrollada en **Vue.js** para la gestión de horarios y turnos, diseñada bajo un entorno corporativo DAW.

## 🚀 Despliegue con Docker (Local)

Para asegurar que la aplicación funcione en cualquier entorno de forma aislada, utilizamos un proceso de construcción en dos etapas (Multi-stage build) con un servidor **Nginx** para la producción.

### 📋 Requisitos Previos
* **Docker Desktop** instalado y en ejecución.
* Conexión a internet para la descarga de imágenes base y acceso a la API externa.

---

### 🛠️ Instalación y Ejecución

Sigue estos pasos desde la terminal en la raíz del proyecto:

1.  **Construir la imagen:**
    Este paso instala las dependencias de Node.js y compila el proyecto para producción.
    ```bash
    docker compose build
    ```

2.  **Levantar el contenedor:**
    Inicia el servidor web en segundo plano.
    ```bash
    docker compose up -d
    ```

3.  **Acceder a la Web:**
    Una vez levantado, abre tu navegador en:
    > [http://localhost:8080](http://localhost:8080)

---

### ⚙️ Comandos de Gestión Rápidos

| Acción | Comando |
| :--- | :--- |
| **Detener** el contenedor | `docker compose stop` |
| **Iniciar** tras una parada | `docker compose start` |
| **Ver logs** en tiempo real | `docker logs -f mi-proyecto-vue` |
| **Eliminar** todo (limpieza) | `docker compose down --rmi all` |

---

## 📦 Cómo exportar/importar la imagen (Sin Registro)

Si necesitas llevarte el contenedor a otra máquina sin usar Docker Hub, puedes hacerlo mediante un archivo físico:

1.  **Exportar (PC Origen):**
    ```bash
    docker save -o mi-proyecto-vue.tar mi-proyecto-vue
    ```
2.  **Importar (PC Destino):**
    ```bash
    docker load -i mi-proyecto-vue.tar
    ```
3.  **Ejecutar tras cargar:**
    ```bash
    docker run -d --name mi-contenedor-vue -p 8080:80 mi-proyecto-vue
    ```

---

## 📝 Notas del Proyecto
* **Etapas:** Cada franja horaria incluye obligatoriamente una descripción detallada según los requisitos del sistema.
* **API:** El frontend conecta con servicios REST externos en la IP `44.207.19.239`.
* **Ordenación:** Las franjas se ordenan automáticamente por ID de forma ascendente.

---
