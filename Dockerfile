FROM skypilot/aws:latest

ARG PACKAGE_NAME
ARG VERSION
ARG VERSION_STAGE
ENV \
  PLATFORM_NAME=${PACKAGE_NAME} \
  PLATFORM_VERSION=${VERSION} \
  PLATFORM_VERSION_STAGE=${VERSION_STAGE}

RUN mkdir -p \
  /var/lib \
  /var/project

RUN touch /root/.bashrc && \
  echo "export PS1=\"\u@${PACKAGE_NAME}-${PLATFORM_VERSION} [\w] \$ \"" >> /root/.bashrc

COPY src/ /var/lib/

WORKDIR /var/project

