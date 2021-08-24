##############  STAGE BASE  ###########################
#1: imagen de la versión de node en base a alpine
FROM node:10-alpine as base 

#2: exponer el puerto cuando se necesite
EXPOSE 3000

#3: definir la variable 
ENV NODE_ENV=production

#4: crear la carpeta de trabajo
WORKDIR /opt

#5: copiar el package
COPY package*.json ./

#6: ejecutar la instalación de las librerias
RUN npm config list \
    && npm ci \
    && npm cache clean --force

##############  STAGE DEV  ###########################
# En maquina local
FROM base as dev 

#1: Reescribir la variable de entorno
ENV NODE_ENV=development

#2: Definir el path de las librerías
ENV PATH=/opt/node_modules/.bin:$PATH

#3: Definir la carpeta de trabajo
WORKDIR /opt

#4: Instalar las librerías de desarrollo
RUN npm install --only=development

#5: Definir una carpeta con los fuentes
WORKDIR /opt/app

#6: Ejecutar el comando con nodemon
CMD ["nodemon", "./", "--inspect=0.0.0.0:9229"]

##############  STAGE SOURCE  ###########################
FROM base as source

#1: Crear carpeta de trabajo
WORKDIR /opt/app

#2: Copiar los archivos fuentes
COPY . .

##############  STAGE TEST  ###########################
FROM source as test

#1: Reescribir la variable de entorno
ENV NODE_ENV=testing

#2: Definir el path de las librerías
ENV PATH=/opt/node_modules/.bin:$PATH

#3: Completar las librerías de (prod+dev)
COPY --from=dev /opt/node_modules /opt/node_modules

#4: Ejecutar el lintener
RUN standard --fix

#5: Ejecutar las pruebas unitarias
RUN node test

#6: Ejecutar pruebas de integración con docker-compose o por otro medio
CMD ["npm", "run", "int-test"]

##############  STAGE AUDIT  ###########################
FROM test as audit

RUN npm audit

# aqua microscanner, which needs a token for API access
# note this isn't super secret, so we'll use an ARG here
# https://github.com/aquasecurity/microscanner
ARG MICROSCANNER_TOKEN
ADD https://get.aquasec.com/microscanner /
RUN chmod +x /microscanner
RUN apk add --no-cache ca-certificates && update-ca-certificates
RUN /microscanner $MICROSCANNER_TOKEN --continue-on-failure

##############  STAGE PROD  ###########################
FROM source as prod

CMD ["node", "./"]