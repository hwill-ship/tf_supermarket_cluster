# Chef Supermarket Terraform Cluster - Proof of Concept

This is a terraform configuration to spin up a Chef Server and Supermarket Server and configure them so that Supermarket uses the Chef Server for auth.

This currently only works with AWS.

## Requirements
You must have Git, ChefDK, and Terraform installed on your local workstation.

You must have an AWS account including an AWS Access Key, AWS Secret Key, and AWS IAM user

## What this does

This Terraform config will:

1. Spin up a Supermarket server in AWS
2. Spin up a Chef Server in AWS, then register the Supermarket with the Chef Server so Supermarket can use oc_id for auth
3. Make some changes to your workstation - including setting up a .chef/knife.rb file with the new Chef Server and Supermarket information
4. Upload a databag with information for Supermarket to use when it is configured 
5. Spin up a new RDS instance and connect it to your Supermarket
6. Spin up a new Elasticache instance and connect it to your Supermarket
7. Spin up a new S3 bucket for artifact storage and connect it to your Supermarket

This is a high level overview, please see the actual config files for more detail about what is executed when.

## Usage

First clone this repo to your local workstation

```bash
  $ git clone git@github.com:nellshamrell/tf_supermarket_cluster.git
```

Then change into that directory

```bash
  $ cd tf_supermarket_cluster
```

Now copy the terraform.tfvars.example to a new file called terraform.tfvars

```bash
  $ cp terraform.tfvars.example terraform.tfvars
```

Now open up then new file with your preferred text editor and fill in the appropriate values (i.e. AWS Access Key, AWS Key Pair, etc.)

Next, get the modules included in this repo:

```bash
  $ terraform get
```

Check that your Terraform config looks good

```bash
  $ terraform plan
```

Then spin up your cluster!

```bash
  $ terraform apply
```

When you're done, use this command to destroy your cluster!

```bash
  $ terraform destroy
```
