This was built to go along with Learn Kubernetes the Hard Way. 
This will allow you to build the infrastructure utilizing terraform and then run ansible plays up to the point where you left off.

While this was built using GCP I will be investigating including an AWS method utilizing the free tier as much as possible.

Also this does not include any prep work for steps 1 and 2. You will need to follow those instructions and have the required packages installed.

To use:
```
cd terraform
terraform init
terraform apply -auto-approve
cd ..
ansible-playbook main.yaml
```

To delete:
```
cd terraform
terraform destroy -auto-approve
```