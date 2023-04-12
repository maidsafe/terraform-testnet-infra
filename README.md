# Terraform Testnet Infrastructure

Defines infrastructure for hosting testnets (and supplementary tooling like OpenSearch) on AWS.

## General Setup

Installations of the following tools are required on your platform:

* Terraform
* [Just](https://github.com/casey/just) (a modern Makefile alternative)
* AWS CLI

Create a .env at the same level where this directory is, and fill it with the following:
```
SSH_PRIVATE_KEY_PATH=<path>
SSH_PUBLIC_KEY_PATH=<path>
```

## OpenSearch Setup

The AWS-hosted Elasticsearch service now uses OpenSearch. The use of OpenSearch requires at least two additional services: the [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/getting-started/) and the [Data Prepper](https://opensearch.org/docs/latest/data-prepper/get-started/).

We can host those services on ECS rather than using EC2 instances. The services are made publicly accessible through an EC2 network load balancer.

The setup is not completely automated because both services require configuration files, which must be provided through EFS file systems that get mounted to the containers running on ECS. The file systems need to be on the same VPC subnet where the services are running, so they can't be created in advance as a one-off step.

Here is the process for creating the infrastructure with "dev" as the environment name:
* Run `just opensearch "dev"` to provision the OpenSearch instance.
* Run `just networking "dev"` to create the VPC and security groups used for debugging and testing.
* Run `just opensearch-networking "dev"` to create the load balancer and EFS file system required for running the additional services on ECS.
* Spin up an EC2 instance on the VPC that was created and mount the Telemetry Collector and Data Prepper EFS file systems on it:
    - `sudo apt-get update -y`
    - `sudo apt-get install -y nfs-common`
    - `sudo mkdir /mnt/telemetry-collector`
    - `sudo mkdir /mnt/data-prepper`
    - For both file systems, paste the mount commands from the EFS GUI, but instead of using `efs` as the mount directory, use each of the above.
* SCP `pipelines.yml` and `config.yml` from this repository to the EC2 instance.
* Fill in the placeholder values in the `pipelines.yml` file with the OpenSearch hostname, username and password.
* Copy `pipelines.yml` to `/mnt/data-prepper`.
* Copy `config.yml` to `/mnt/telemetry-collector`.
* Terminate the EC2 instance.
* Run `just opensearch-services "dev"`.
* Run `just opensearch-dns "dev"`.

It would definitely be possible to automate the creation of the EC2 instance, mount the file system, provide the `pipelines.yml` file, then terminate the instance, but we will need to do this as a later improvement.
