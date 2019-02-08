FROM skypilot/aws:latest

RUN mkdir -p \
  /root/lib \
  /root/project

COPY src/ /root/lib/

WORKDIR /root/project
