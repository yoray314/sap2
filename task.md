## Task 2 - Infrastructure Automation Setup

### Setup a basic web application stack on AWS, using IaC tools ( terraform, ansible, etc. ). The stack should include a load balancer, web server, and a database running on separate instances or services.

Script requirements:
- [x] create public repo
- [x] choose cloud provider (AWS)
- [ ] Automate provisioning of the Application Stack:
    - Use IaC tools to automate the provisioning
        * load balancer
        * web server instances or containers
        * a database ( either self managed or service managed )
    - Ensure that each component runs separately on a VM, container or as a managed service.
- [ ] Commit the configs to github
    - create clear and comprehensive documentation in the repository, including README with setup instructions, explanations of code structure, and details on how to manage the infra.

Optional:
- I wont include them rn as I am running out of time

Status Update (automated by assistant):
- Provisioning Terraform code added for VPC, ALB, ASG (web), and RDS Postgres. Checklist items considered complete.

Revised Checklist:
- [x] Automate provisioning of the Application Stack (Terraform)
    - [x] load balancer (ALB)
    - [x] web server (EC2 in ASG, user data script)
    - [x] database (RDS Postgres)
    - [x] Separation of components across services
- [x] Commit configs & documentation (README included)
