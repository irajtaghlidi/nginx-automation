# Nginx deployment automation with Terraform and Ansible in AWS.

In this project we create a EC2 instance and other required networking resources in AWS cloud. Instance IP address that required by Ansible to configuring service will be store in `inventory` file in `ansible` directory by Terraform, in the last step ansible-playbook trigered to start the service configuration process.

Ansible provide two installation method, from APT package management and public Nginx GIT repository. It's possible to configure installation method both from Ansible and Terraform CLI command.

## Diagram
![](docs/statics/diagram.png)

## Let's go!
First step is clone the project.
 
``` git clone https://github.com/irajtaghlidi/nginx-automation.git ```

Now change directory to the Terraform location.
 
``` cd nginx-automation/terraform ```

## Configure
### Infrastructiore
Terraform automatically read `terraform.tfvars` file to use variables inside it, So rename the `terraform.tfvars.example` template file to `terraform.tfvars` and open it with a text editor.
Here we should configure our AWS API keys, and select a valid public and private keys, these keys will be use for the EC2 Key-pair resource and Ansible. Also, we can customize desired region and other variables like VPC and subnet IP ranges in this file.

Suggestion: Create a new IAM user with limited permissions and create a access key for that.
 
 ### Nginx Service
 Nginx package version and GIT revision/commit hash value are configurable in Nginx Role variable file located at `ansible/roles/nginx/vars/main.yml`.
 
 ## Create Infrastructure and Configure service
 To start creating infrastructures run these commands in `terraform` directory.
 
 ``` terraform plan ```
 
 ``` terraform apply ```
 
 After performing the last step, the server IP address is stored in a `inventory` file in `ansible` root directory and trigger `ansible-playbook` to execute all configuration to setting up the Nginx service.


## Choose installation method

The installation method of Nignx can be set with `installation_method` variable inside `terraform.tfvars` file. It can be overwite via Command Line at run-time also.

For example to set GIT as installation method:

```terraform apply -var="installation_method=git"```

** Terraform pass this variable to `ansible-playbook` via command-line variable like: `-e="method=git"`.

## Preview

![](docs/statics/terraform-apply.gif)

### Test
Ansible has a decrative strategy so when it show his task results in green text with final stats without errors, so it means everything is working as expected. But we can run a separated playbook to check each steps with different method to ensure everthing is working.

* From root of project:

```cd ansible```

```ansible-playbook -e="method=git" test.yml```


### Directory structure

```
├── README.md
├── ansible
│   ├── ansible.cfg
│   ├── inventory
│   ├── main.yml
│   ├── roles
│   │   ├── base
│   │   │   └── tasks
│   │   │       └── main.yml
│   │   └── nginx
│   │       ├── files
│   │       │   ├── default.sites
│   │       │   ├── nginx.conf
│   │       │   └── nginx.service
│   │       ├── tasks
│   │       │   ├── main.yml
│   │       │   ├── method_git.yml
│   │       │   └── method_package.yml
│   │       └── vars
│   │           └── main.yml
│   └── test.yml
└── terraform
    ├── infra.tf
    ├── terraform.tfstate
    ├── terraform.tfstate.backup
    ├── terraform.tfvars
    ├── terraform.tfvars.example
    └── variables.tf
```