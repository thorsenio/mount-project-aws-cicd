# mount-project-aws-cicd

Docker image for managing a CI/CD pipeline hosted on AWS

Variables are read from the following two files:
- `config/project-variables.sh`
- `config/regional-variables.sh`

## General

#### 1. Set values in the variables files

Enter regional and project-specific settings into
- `config/project-variables.sh`
- `config/regional-variables.sh`

#### 2. Mount the project into the container:

```bash
mount-project-aws-cicd [DEPLOYMENT_NAME]
```

In all stack operations, use the `--wait` option if you want to wait for the stack operation to be completed.

## ECS cluster stack

### 1. To create or update an ECS cluster stack

This stack consists of an ECS cluster, VPC spanning multiple availability zones, public & private
subnets in each zone, and two EC2 instances (one instance in development).

```bash
put-ecs-cluster-stack.sh [--wait]
```

##### Delete the stack when it is no longer needed

```bash
delete-ecs-cluster-stack.sh [--wait]
```

## CI/CD pipeline

### 1. Create or update the pipeline stack:

```bash
put-codepipeline-stack.sh [--wait]
```

##### Delete the stack when it is no longer needed

```bash
delete-codepipeline-stack.sh [--wait]
```

## Containerized site in ECS cluster

### 1. Create or update the ECS site stack:

```bash
put-ecs-site-stack.sh [--wait]
```

##### Delete the stack when it is no longer needed

```bash
delete-ecs-site-stack.sh [--wait]
```

## Static site served from S3

#### 1. Create or update the S3 site stack:

```bash
put-s3-site-stack.sh [--wait]
```

##### Delete the stack when it is no longer needed

```bash
delete-s3-site-stack.sh [--wait]
```

##### Utility scripts

```bash
# Forward a port to one of the EC2 container instances
forward-to-ecs-instance INSTANCE_INDEX PORT

# SSH into one of the EC2 container instances
ssh-into-ecs-instance INSTANCE_INDEX
```


TODO: Add an 'init' argument to the environment activation script; when used, it will copy
the variables files into the project's `config` directory. 

TODO: Make the scripts easier to access.
