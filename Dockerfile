FROM ubuntu:latest

RUN apt update && \
    apt install -y openssl

VOLUME [ "/root_demo" ]

WORKDIR /root_demo

CMD /bin/bash