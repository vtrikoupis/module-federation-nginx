FROM node:14.0.0-alpine as build

RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh

WORKDIR /usr/src/app

COPY package.json /usr/src/app
COPY package-lock.json /usr/src/app
COPY lerna.json /usr/src/app

COPY apps/core/package.json /usr/src/app/apps/core/
COPY apps/core/package-lock.json /usr/src/app/apps/core/

COPY apps/another_micro_app/package.json /usr/src/app/apps/another_micro_app/
COPY apps/another_micro_app/package-lock.json /usr/src/app/apps/another_micro_app/

COPY apps/shared/package.json /usr/src/app/apps/shared/
COPY apps/shared/package-lock.json /usr/src/app/apps/shared/

RUN npm ci --ignore-scripts --production --no-optional
RUN npx lerna bootstrap --hoist --ignore-scripts -- --production --no-optional

# Build

COPY . /usr/src/app
RUN cd apps/core && npm run build
RUN cd apps/another_micro_app && npm run build
RUN cd apps/shared && npm run build


# # set up production environment
FROM nginx:alpine
# # copy the build folder from react to the root of nginx (www)   /error
COPY --from=build /usr/src/app/apps/core/dist /usr/share/nginx/html
COPY --from=build /usr/src/app/apps/another_micro_app/dist /usr/share/nginx/modules/another_micro_app
COPY --from=build /usr/src/app/apps/shared/dist /usr/share/nginx/modules/shared

# --------- rewrite nginx conf when using react router ----------
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx/nginx.conf /etc/nginx/conf.d
# --------- expose port 80 when using react router ----------
EXPOSE 80

# start nginx 
CMD ["nginx", "-g", "daemon off;"]