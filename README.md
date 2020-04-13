# Automation

This document aims to document the process to deploy the infrastructure and the different applications for the following components:
- [Mad API](https://github.com/AmFlint/mad-api)
- [Mad Clients](https://github.com/AmFlint/mad-client)
- [Mad Website](https://github.com/AmFlint/mad-web)

This infrastructure is deployed on `Amazon Web Services` via [Terraform modules](./terraform) and the applications are provisioned on this infrastructure via [Ansible Playbooks](./ansible).

## How the system works

In this system we have:
- API servers, built on top of Socket.io's websockets, to deliver real-time data about clients's health.
- clients, connecting to API servers via Websockets, pushing data about their health on a given period of time
- Web Clients, connecting to API servers via Websockets, to display the client's health, and update in real-time

In order to scale websocket Applications (especially the API component), we need:
- An adapter, to make sure that every API are in-sync, and may broadcast events to Web Clients, connected to either one of the API node. For this task, I'm using Redis (backed by ElastiCache from AWS) as a event-bus.
- A Load-balancer/Proxy with Sticky Sessions feature, as we need our clients to only communicate with the same API node, once the connection is opened. For this, I'm using `nginx` as AWS ELB does not provide sticky sessions for web sockets.
- A datastore, to store the data for each client, for this, I'm using `Redis`.

## Requirements

- Install Python 3
- Install [Terraform](https://www.terraform.io/downloads.html)
- Install [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- Install [required PIP dependencies](./ansible.requirements.txt):
  ```bash
  pip install -r ansible/requirements.txt
  ```
- If you wish to build and deploy the docker images stored in each repository, you'll need:
  - `docker` installed
  - a registry namespace/accoutn (Google Container Registry, Docker Hub...)
- Create an [AWS account](https://aws.amazon.com/fr/)
- Sign in to your AWS Account, and create an IAM User with the following policies:
  - `AmazonEC2FullAccess` (Manage EC2 Instances, IPs, Security Groups, Key Pairs and Load Balancers)
  - `AmazonElastiCacheFullAccess` (Manage ElastiCache clusters / Redis instances)
- Retrieve your credentials for your IAM User (Access Key ID and Secret Access Key)

## Provision the infrastructure - Terraform

This system requires the following components, installed via [Terraform](./terraform):
- `API`:
  - `x` EC2 instances for API
  - security group for the API instances, allowing Ingress Traffic for 22 (SSH) and 3000 (API service)
  - 1 EC2 instance for API Load Balancers, unfortunately ELB does not provide sticky sessions for Websockets, so we have to use a custom Proxy with `NGINX`, deployed on this EC2 instance.
  - 1 Elastic IP, attached to the LB EC2 Instance
  - 1 Security Group, allowing ingress to port 22 (SSH) and port 80 (NGINX)
  - 1 ElastiCache Cluster composed of 1 instance of `Redis`
  - 1 Security Group for ElastiCache, to allow Ingress on port 6379 only from API EC2 Instances
- `Client`:
  - `x` EC2 instances for clients
  - 1 Security Group for Clients, allowing ingress for 22 (SSH)
- `Web`:
  - `x` EC2 instances for Web console
  - 1 Security group for web consoles, allowing ingress for 22 (SSH) and 80 (NGINX serving website)
  - 1 Elastic Load Balancer instance, balancing traffic on the Web Console EC2 Instances

`x` being the number of instances for each component, provided via variables to each module.

To deploy the infrastructure on your AWS Account:
- Create a `SSH` Key pair:
  ```bash
  ssh-keygen -t rsa
  ```

- Run terraform:
  ```bash
  # export your IAM User's credentials, terraform will retrieve it from environment
  export AWS_SECRET_ACCESS_KEY=<your-secret-key>
  export AWS_ACCESS_KEY_ID=<your-access-key>
  # Use your SSH Public key from the pair you created, then you'll be able to use your private key to log in to your instances
  export SSH_PUBLIC_KEY_FILE=<path-to-your-public-key>

  terraform init
  terraform apply -var ssh_public_key_file=$SSH_PUBLIC_KEY_FILE
  ```


## Provision the applications with Ansible

Now that we have provisioned our infrastructure on Amazon Web Services, we'll need to deploy our applications.

Our applications run inside `docker containers`, via `docker-compose` on each of instance. You'll need to build and push your docker images before han, with the following commands:
```bash
export REGISTRY_IMAGE=amasselot
export REGISTRY_TAG=v1.0

# Inside the mad API repository, cloned locally
docker build -t $REGISTRY_IMAGE/mad-api:$REGISTRY_TAG .
docker push $REGISTRY_IMAGE/mad-api:$REGISTRY_TAG

# Inside the mad Client repository, cloned locally
docker build -t $REGISTRY_IMAGE/mad-client:$REGISTRY_TAG .
docker push $REGISTRY_IMAGE/mad-client:$REGISTRY_TAG

# Inside the mad WEB repository, cloned locally
# As we're using create-react-app, environment variables are compiled at build time with Webpack
# So we need to pass the API URL as a build arg at docker build time
# to do that, retrieve your api_lb elastic IP either with terraform state, or via AWS's console
export API_URL=http://<elastic-ip-retrieved-from-AWS-console>
docker build -t $REGISTRY_IMAGE/mad-web:$REGISTRY_TAG --build-arg REACT_APP_API_URL=$API_URL .
docker push $REGISTRY_IMAGE/mad-web:$REGISTRY_TAG
```

**Note that you'll have to re-build the web image anyway, because of the build argument for API URL**. For Client and API, you may use my images.

I used `Ansible dynamic inventory for AWS`, to make it easy to scale and provision new instances. This dynamic inventory will create an inventory by querying AWS EC2's APIs, which is why you'll need to install `boto` (see the Requirements part), and retrieve your IAM credentials.

The playbooks are split in different roles:
- `Common`: Install common packages on each instance, required to use Ansible modules such as `docker_compose` for example
- `geerlingguy.docker`: Open source role to install `docker` and `docker-compose` on our instances
- `api`: Install our API docker-compose project, pull docker images from given registry and run docker-compose project.
- `api_lb`: Install the proxy/Load Balancer in front of our API instances, with the specific configuration for sticky sessions.
- `client`: install the client docker image via a docker-compose project on our client instances
- `web`: install the web docker-compose project on our web instances

To provision the applications:
- First, make sure to update the variables for your infrastructure:
  - [API LB inventory variables](./ansible/inventory/group_vars/tag_Name_api_lb.yml), and use your API EC2 instances's IP/DNS
  - [API's redis configuration](./ansible/inventory/group_vars/tag_Name_api.yml), use the DNS name provided for your ElastiCache node (Redis)
  - [Client's API URL](./ansible/inventory/group_vars/tag_Name_client.yml), use the Elastic IP provided for your api_lb EC2 Instance
  - [Web's API URL](./ansible/inventory/group_vars/tag_Name_web.yml), use the Elastic IP provided for your api_lb EC2 Instance
- Then, run the ansible playbook:
```bash
export ANSIBLE_CFG=./ansible.cfg
# AWS Environment variables required for dynamic inventory to query EC2's APIs
export AWS_ACCESS_KEY_ID=<your-aws-access-key-id>
export AWS_SECRET_ACCESS_KEY=<your-aws-secret-key>

cd ansible
# --become flag for first run, as we install docker and need root privileges, for redeployment, we won't need it
ansible-playbook -i inventory/ec2.py playbook.yml --user ubuntu --become
```

To access your web console, get your DNS Name provided for your Web's Elastic Load balancer from AWS console.

You can use this playbook to re-deploy a new version of the application, this is what I'm doing for CI/CD for each component:
- [API](https://github.com/AmFlint/mad-api/tree/master/.github/workflows/deploy.yml)
- [Web](https://github.com/AmFlint/mad-web/tree/master/.github/workflows/deploy.yml)
- [Client](https://github.com/AmFlint/mad-client/tree/master/.github/workflows/deploy.yml)
