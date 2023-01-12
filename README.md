# Terraform Testnet Infrastructure

Defines infrastructure for hosting testnets (and supplementary tooling like OpenSearch) on AWS.

## OpenSearch Setup

The AWS-hosted Elasticsearch service now uses OpenSearch. The use of OpenSearch requires at least two additional services: [the OpenTelemetry collector](https://opentelemetry.io/docs/collector/getting-started/) and the [Data Prepper](https://opensearch.org/docs/latest/data-prepper/get-started/).

We can host those services on ECS rather than using EC2 instances. The services are made publicly accessible through an EC2 network load balancer.

The setup is not completely automated because the Data Prepper requires a configuration file pointing to the OpenSearch service, which must be provided through an EFS file system which is mounted to the container running on ECS. The EFS file system needs to be on the same VPC subnet where the service is running, so it can't be created in advance as a one-off step.

Here is the process for creating the infrastructure:
* Run `make opensearch-dev` to provision the OpenSearch instance.
* Run `make networking-dev` to create the VPC, load balancer and EFS file system required for running the additional services on ECS.
* Spin up an EC2 instance on the VPC that was created and mount the EFS file system to it.
* Fill in the placeholder values in the `pipelines.yml` file in this repository with the OpenSearch hostname, username and password.
* Put the `pipelines.yml` at the root of the mounted EFS file system.
* Terminate the EC2 instance.
* Run `make services-dev`.

It would definitely be possible to automate the creation of the EC2 instance, mount the file system, provide the `pipelines.yml` file, then terminate the instance, but we will need to do this as a later improvement.
