FROM alpine

ENV ARTILLERY_YAML_FILE='/tests/simple-socketio-load-test.yaml'
ENV REPORT_NAME='artillery-report'
ENV AZURE_STORAGE_CONNECTION_STRING=''

WORKDIR /artillery

COPY . .

RUN apk add --update nodejs npm && \
    npm install -g artillery artillery-engine-socketio-v3 && \
    apk update && \
    apk add bash py-pip && \
    apk add --virtual=build gcc libffi-dev musl-dev openssl-dev python3-dev make && \
    pip --no-cache-dir install -U pip && \
    pip --no-cache-dir install azure-cli && \
    apk del --purge build

ENTRYPOINT ["/bin/ash","run-tests.sh"]