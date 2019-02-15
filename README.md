# aws-cicd

Docker image for managing a CI/CD pipeline hosted on AWS

Variables are read from the following two files:
- `config/project-variables.sh`
- `config/regional-variables.sh`

### General

##### 1. Set values in the variables files

Enter regional and project-specific settings into
- `config/project-variables.sh`
- `config/regional-variables.sh`

##### 2. Activate the containerized environment:

```bash
./activate-aws-cicd.sh
```

### ECS cluster stack

##### 1. Create a key pair for the ECS cluster (if one doesn't exist already)

```bash
../lib/aws/ec2/create-key-pair.sh
```

##### 2. Create or update the ECS stack:

```bash
../lib/aws/cloudformation/put-ecs-stack.sh
```

##### Delete the stack when it is no longer needed

```bash
../lib/aws/cloudformation/delete-ecs-stack.sh
```

### CI/CD pipeline

##### 1. Create or update the pipeline stack:

```bash
../lib/aws/cloudformation/put-codepipeline-stack.sh
```

##### Delete the stack when it is no longer needed

```bash
../lib/aws/cloudformation/delete-codepipeline-stack.sh
```

### Containerized site in ECS cluster

##### 1. Create or update the ECS site stack:

```bash
../lib/aws/cloudformation/put-ecs-site-stack.sh
```

##### Delete the stack when it is no longer needed

```bash
../lib/aws/cloudformation/delete-ecs-site-stack.sh
```

### Static site served from S3

##### 1. Create or update the S3 site stack:

```bash
../lib/aws/cloudformation/put-s3-site-stack.sh
```

##### Delete the stack when it is no longer needed

```bash
../lib/aws/cloudformation/delete-ecs-site-stack.sh
```

##### Utility scripts

```bash
# Forward a port to one of the EC2 container instances
../lib/aws/ec2/forward-to-ecs-instance INSTANCE_INDEX PORT

# SSH into one of the EC2 container instances
../lib/aws/ec2/ssh-into-ecs-instance INSTANCE_INDEX
```


TODO: Add an 'init' argument to the environment activation script; when used, it will copy
the variables files into the project's `config` directory. 

TODO: Make the scripts easier to access.
