FROM node:24.22.3-alpine AS build
RUN apk upgrade --no-cache zlib && npm install --global npm@12.2.3

WORKDIR /usr/src/app
COPY package.json package-lock.json ./
COPY apps/core/package.json apps/core/
COPY apps/another_micro_app/package.json apps/another_micro_app/
COPY apps/shared/package.json apps/shared/
RUN npm ci
COPY apps/ apps/
RUN npm run build

FROM nginx:1.30.7-alpine
RUN apk upgrade --no-cache zlib
COPY --from=build /usr/src/app/apps/core/dist /usr/share/nginx/html
COPY --from=build /usr/src/app/apps/another_micro_app/dist /usr/share/nginx/html/modules/another_micro_app
COPY --from=build /usr/src/app/apps/shared/dist /usr/share/nginx/html/modules/shared
