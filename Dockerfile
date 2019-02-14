FROM skypilot/aws:latest

RUN mkdir -p \
  /var/lib \
  /var/project

COPY src/ /var/lib/

WORKDIR /var/project

