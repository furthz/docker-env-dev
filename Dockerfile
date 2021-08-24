FROM node:10-alpine as base 

EXPOSE 3000

ENV NODE_ENV=production

WORKDIR /opt

COPY package*.json ./

RUN npm config list \
    && npm install \
    && npm cache clean --force

#STAGE de desarrollo (maquinas locales)
FROM base as dev

ENV NODE_ENV=development

ENV PATH=/opt/node_modules/.bin:$PATH

WORKDIR /opt

RUN npm install --only=development

WORKDIR /opt/app

CMD ["nodemon", "./", "--inspect=0.0.0.0:9229"]

#STAGE SOURCE
FROM base as source

WORKDIR /opt/app

COPY . .

#TESTING
FROM source as test

ENV NODE_ENV=testing
ENV PATH=/opt/node_modules/.bin:$PATH

# this copies all dependencies (prod+dev)
COPY --from=dev /opt/node_modules /opt/node_modules

# run linters as part of build
# be sure they are installed with devDependencies
#RUN eslint . 
#RUN npx standard


# run unit tests as part of build
RUN standard --fix

RUN node test

# run integration testing with docker-compose later
#CMD ["npm", "run", "int-test"]

FROM source as prod

CMD ["node", "./"]