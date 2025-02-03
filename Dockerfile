FROM alpine:latest

RUN apk update && \
    apk add openssl make bash

ENV PYTHONUNBUFFERED=1
ENV PATH=/root/.local/bin:${PATH}
RUN apk add --update --no-cache python3 pipx
RUN pipx install jinja2-cli

VOLUME [ "/root" ]

WORKDIR /root

CMD ["/bin/bash"]
