FROM skypilot/aws:latest

RUN apk update && \
  apk upgrade && \
  apk add \
    --no-cache \
    docker

# The aws-cicd source code is copied into this directory
ARG PLATFORM_DIR='/var/lib'
# The project consuming this container should be mounted into this directory
ARG PROJECT_DIR='/var/project'

ARG PACKAGE_NAME
ARG VERSION
ARG VERSION_STAGE
ENV \
  PLATFORM_NAME=${PACKAGE_NAME} \
  PLATFORM_VERSION=${VERSION} \
  PLATFORM_VERSION_STAGE=${VERSION_STAGE} \
  PATH="${PLATFORM_DIR}/aws/cloudformation:${PLATFORM_DIR}/aws/ec2:${PLATFORM_DIR}/aws/ecr:${PLATFORM_DIR}/aws/codecommit:${PATH}" \
  PROJECT_DIR="${PROJECT_DIR}"

RUN mkdir -p \
  ${PLATFORM_DIR} \
  ${PROJECT_DIR}

RUN touch /root/.bashrc && \
  echo "export PS1=\"\u@${PACKAGE_NAME}-${PLATFORM_VERSION}-${VERSION_STAGE} [\w] \$ \"" >> /root/.bashrc

COPY src/ ${PLATFORM_DIR}

WORKDIR ${PROJECT_DIR}
