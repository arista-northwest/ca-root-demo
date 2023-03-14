FROM alpine:latest

RUN apk update && \
    apk add openssl make bash

ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3 && \
    python3 -m ensurepip && \
    pip3 install --no-cache --upgrade pip setuptools && \
    pip3 install jinja2-cli

VOLUME [ "/root" ]

WORKDIR /root

CMD /bin/bash