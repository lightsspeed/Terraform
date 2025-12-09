#!/bin/bash

terraform fmt
terraform validate
terraform plan 
terraform apply -auto-approve  
terraform output > outputs.txt