# CloudIntel Infrastructure

Terraform, modular, per-environment state.

```
modules/
  storage/    DynamoDB single table + S3 reports bucket (KMS, versioned, private)
  auth/       Cognito user pool, client, tier groups
  api/        Lambda + API Gateway HTTP API + IAM least-privilege role
  observability/  CloudWatch alarms, log retention, dashboard
envs/
  dev/        Dev environment composition
```

## Bootstrap
```bash
cd envs/dev
terraform init
terraform plan -var="project=cloudintel" -var="environment=dev"
terraform apply
```

State backend is commented out in `envs/dev/backend.tf` — uncomment once the S3 bucket and
DynamoDB lock table exist. Chicken-and-egg is deliberate: bootstrap local, migrate remote.
