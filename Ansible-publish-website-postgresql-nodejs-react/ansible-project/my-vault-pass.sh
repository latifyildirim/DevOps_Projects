#! /bin/bash
aws --region=us-east-1 ssm get-parameters --names "my-passwd" --query "Parameters[*].{Value:Value}" --output text

# # ansible-playbook play-newrole.yml --vault-password-file ./my-vault-pass.sh