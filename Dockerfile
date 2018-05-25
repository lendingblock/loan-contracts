#Build part 1: install dependencies
FROM node:10-alpine as intermediate 
ARG SSH_KEY

RUN apk update >/dev/null && \
    apk --no-cache add openssh git libc6-compat curl && \
    mkdir $HOME/.ssh/ && \
    chmod 0700 $HOME/.ssh && \
    ssh-keyscan github.com > $HOME/.ssh/known_hosts && \
    echo "${SSH_KEY}" > $HOME/.ssh/id_rsa && \
    chmod 600 $HOME/.ssh/id_rsa

WORKDIR /app

COPY . .

RUN npm install
RUN rm -rf $HOME/.ssh 

#Build part 2: removed ssh keys and start app
FROM node:10-alpine

WORKDIR /app

COPY --from=intermediate /app /app

ENTRYPOINT ["./entrypoint.sh"]
CMD ["truffle", "test"]
