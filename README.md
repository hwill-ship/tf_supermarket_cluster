# This is for Test use ONLY!  I do not recommend using it in production!

# Chef Supermarket Terraform Cluster - Proof of Concept

This is a terraform configuration to spin up a Chef Server, Supermarket Server, and Fieri Server and configure them to work together

## Requirements
You must have Git, ChefDK, and Terraform installed on your local workstation.

You must have an AWS account including an AWS Access Key, AWS Secret Key, and AWS IAM user

## What this does

This Terraform config will:

1. Spin up a [Supermarket](https://github.com/chef/supermarket) server in AWS
2. Spin up a [Chef Server](https://github.com/chef/chef-server) in AWS, then register the Supermarket with the Chef Server so Supermarket can use oc_id for auth
3. Make some changes to your workstation - including setting up a .chef/knife.rb file with the new Chef Server and Supermarket information
4. Upload a databag with information for Supermarket to use when it is configured
5. Spin up a new RDS instance and connect it to your Supermarket
6. Spin up a new Elasticache instance and connect it to your Supermarket
7. Spin up a new S3 bucket for artifact storage and connect it to your Supermarket
8. Spin up a [Fieri](https://github.com/chef/fieri) server in AWS

This is a high level overview, please see the actual config files for more detail about what is executed when.

## Usage

NOTE: These instructions are confirmed to work on an Ubuntu 14.04 workstation.  More workstation confirmations coming soon!

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

And you have a ready to use Supermarket, Chef Server, and Fieri server (along with an RDS instance, Elasticache instance, and S3 instance all configured to work together!)


It also, however, made some changes to your workstation (though only within the tf_supermarket_cluster directory).  It added a tf_supermarket_cluster/.chef/knife.rb file which is configured to work with the supermarket server in the cluster.  It also downloaded any necessary certificates, so you should be able to immediately start sharing cookbooks on the supermarket server as long as you are in the tf_supermarket_cluster directory.

Here are some instructions and more information:

1. Get the Supermarket public IP address from the AWS Console
2. Visit https://public_ip_address in your browser
3. Click “Sign in”
4. This will bring you to the sign in page for your Chef Server.  Enter in the chef-username and chef-user-password you defined in terraform.tfvars
5. After signing in, you should be brought back to Supermarket
6. Head on back to your terminal and (assuming you are in the tf_supermarket_cluster directory) run $ls chef-server/cookbooks.  This will list the cookbooks that were uploaded to the Chef Server (though not to Supermarket).
7. Try uploading one (note that not all of these can be uploaded to a Supermarket in the current state they are in) by running $knife supermarket share supermarket-wrapper —cookbook-path ‘chef-server/cookbooks’
8. This should upload successfully
9. Create a new cookbook (I like to follow on of the learn chef tutorials to do so).  I’d suggest doing this in the tf_supermarket_cluster directory (feel free to add it to the chef-server/cookbooks directory) because it is already configured to work with the supermarket server spun up in the cluster.  Upload that using the $knife supermarket share command.

And voila!  You have a working Supermarket with two cookbooks uploaded!  Where you take it from here is up to you :)

When you're done with your cluster, use this command to destroy your cluster!

```bash
  $ terraform destroy
```
