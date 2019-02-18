FROM skypilot/aws:latest

ARG PACKAGE_NAME
ARG VERSION
ARG VERSION_POSTFIX
ENV \
  PLATFORM_NAME=${PACKAGE_NAME} \
  PLATFORM_VERSION=${VERSION} \
  PLATFORM_VERSION_POSTFIX=${VERSION_POSTFIX}

RUN mkdir -p \
  /var/lib \
  /var/project

RUN touch /root/.bashrc && \
  echo "export PS1=\"\u@${PACKAGE_NAME} [\w] \$ \"" >> /root/.bashrc

COPY src/ /var/lib/

WORKDIR /var/project

