# Etapa 1: Construcción (Build)
# Se encarga de instalar dependencias y compilar el proyecto
FROM node:lts-alpine as build-stage
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Etapa 2: Producción
# Usa Nginx para servir los archivos generados en la etapa anterior
FROM nginx:stable-alpine as production-stage
COPY --from=build-stage /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]