FROM skypilot/aws:latest

RUN apk update && \
  apk upgrade && \
  apk add \
    --no-cache \
    git \
    docker

# The aws-cicd source code is copied into this directory
ARG PLATFORM_DIR='/var/lib'
# The project consuming this container should be mounted into this directory
ARG PROJECT_DIR='/var/project'

ARG COMMIT_HASH
ARG PACKAGE_NAME
ARG VERSION
ARG VERSION_LABEL
ARG VERSION_STAGE
ENV \
  PLATFORM_COMMIT_HASH=${COMMIT_HASH} \
  PLATFORM_NAME=${PACKAGE_NAME} \
  PLATFORM_VERSION=${VERSION} \
  PLATFORM_VERSION_LABEL=${VERSION_LABEL} \
  PLATFORM_VERSION_STAGE=${VERSION_STAGE} \
  PATH="${PLATFORM_DIR}/aws/acm:${PLATFORM_DIR}/aws/cloudformation:${PLATFORM_DIR}/aws/codecommit:${PLATFORM_DIR}/aws/ec2:${PLATFORM_DIR}/aws/ecr:${PLATFORM_DIR}/aws/route53:${PLATFORM_DIR}/aws/s3:${PLATFORM_DIR}/scripts:${PATH}" \
  PROJECT_DIR="${PROJECT_DIR}"

RUN mkdir -p \
  ${PLATFORM_DIR} \
  ${PLATFORM_DIR}/config-templates \
  ${PROJECT_DIR}

RUN touch /root/.bashrc && \
  echo "export PS1=\"\u@${PACKAGE_NAME}-${PLATFORM_VERSION_LABEL} [\w] \$ \"" >> /root/.bashrc

COPY src/ ${PLATFORM_DIR}
# The config files in `./config/` are shadowed by the project's `./config/`; make a copy
# of it so that the config templates will be available in the container.
COPY src/config/ ${PLATFORM_DIR}/config-templates/

WORKDIR ${PROJECT_DIR}
