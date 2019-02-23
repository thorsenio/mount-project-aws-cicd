FROM skypilot/aws:latest

RUN apk update && \
  apk upgrade && \
  apk add \
    --no-cache \
    docker

ARG PACKAGE_NAME
ARG VERSION
ARG VERSION_STAGE
ENV \
  PLATFORM_NAME=${PACKAGE_NAME} \
  PLATFORM_VERSION=${VERSION} \
  PLATFORM_VERSION_STAGE=${VERSION_STAGE} \
  PATH="/var/lib/aws/cloudformation:/var/lib/aws/ec2:/var/lib/aws/ecr:${PATH}"

RUN mkdir -p \
  /var/lib \
  /var/project

RUN touch /root/.bashrc && \
  echo "export PS1=\"\u@${PACKAGE_NAME}-${PLATFORM_VERSION}-${VERSION_STAGE} [\w] \$ \"" >> /root/.bashrc

COPY src/ /var/lib/

WORKDIR /var/project
