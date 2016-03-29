# Chef Supermarket Terraform Cluster - Proof of Concept

This is a terraform configuration to spin up a Chef Server and Supermarket Server and configure them so that Supermarket uses the Chef Server for auth.

This currently only works with AWS.

## Requirements
You must have Git, ChefDK, and Terraform installed on your local workstation.

You must have an AWS account including a AWS Access Key and Secret Key

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
