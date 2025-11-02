# Log Analyzer Service

This service reads JSON Lines (JSONL) logs, counts `level="ERROR"` entries per service, and raises an alert when the error count crosses a threshold. It is exposed in two ways:

- CLI - run locally or in CI
- HTTP (FastAPI) - run in a container on ECS Fargate behind ALB -> CloudFront

Current deployed endpoint:

- CloudFront URL: https://d3bxdmz0itwwlu.cloudfront.net
  - `GET https://d3bxdmz0itwwlu.cloudfront.net/healthz`
  - `GET https://d3bxdmz0itwwlu.cloudfront.net/analyze?bucket=<bucket>&prefix=<prefix>&threshold=3`

Repo location for this service:

```
log_analyzer/
  app/
    app/
      cli.py
      http_server.py
      core/analyzer.py
      testdata/sample.jsonl
      tests/
    Dockerfile
    README.md
    requirements.txt
    setup.py
    terraform/envs/prod/
```

---

## 1. Run locally

### 1.1 CLI

```bash
cd log_analyzer/app
python3 -m venv .venv
source .venv/bin/activate
pip install -e .

# local file
analyze --file app/testdata/sample.jsonl --threshold 3

# from S3 (uses your AWS creds)
analyze --bucket devops-assignment-logs-430957 \
        --prefix 2025-09-15T16-00.jsonl \
        --threshold 3
```

### 1.2 HTTP (local)

```bash
cd log_analyzer/app
source .venv/bin/activate
uvicorn app.http_server:app --host 0.0.0.0 --port 8080
```

Test:

```bash
curl http://localhost:8080/healthz
curl "http://localhost:8080/analyze?bucket=devops-assignment-logs-430957&prefix=2025-09-15T16-00.jsonl&threshold=3"
```

### 1.3 Docker

```bash
cd log_analyzer/app
docker build -t log-analyzer:local .
docker run --rm -p 8080:8080 log-analyzer:local
```

Then:

```bash
curl http://localhost:8080/healthz
```

---

## 2. Run the deployed version

You can hit the version deployed to AWS:

```bash
curl https://d3bxdmz0itwwlu.cloudfront.net/healthz
curl "https://d3bxdmz0itwwlu.cloudfront.net/analyze?bucket=devops-assignment-logs-430957&prefix=2025-09-15T16-00.jsonl&threshold=3"
```

CloudFront and ALB security groups are already in place, so `/healthz` should return `{"status":"ok"}`.

---

## 3. Deploy (Terraform)

Infrastructure for this service is here:

```
log_analyzer/app/terraform/envs/prod
```

It reuses shared modules from:

```
terraform_modules/
```

Deploy like the pipeline does:

```bash
terraform -chdir=log_analyzer/app/terraform/envs/prod init
terraform -chdir=log_analyzer/app/terraform/envs/prod apply \
  -auto-approve \
  -var="image_tag=<your-ecr-image-tag>"
```

This will:

1. create VPC + subnets + routing,
2. run the container on ECS Fargate,
3. expose it via ALB,
4. front it with CloudFront.

---

## 4. Design decisions

**Workload shape (server vs function)**  
This app is a long-running HTTP service: it exposes `/healthz`, it must be probed by an ALB/CloudFront, and it keeps a FastAPI/uvicorn process listening on port 8080. That is a server pattern (bind + stay up). Lambda is an event pattern (run, return, exit). You can wrap Lambda behind API Gateway, but then API Gateway is the server. For this kind of health-checked service, a container running all the time is the cleaner fit.

**Why ECS Fargate**  
We needed to run a container inside a VPC, keep it up, register it in a target group, and not manage EC2. ECS Fargate gives us:

* no EC2/AMI/patching,
* native integration with ALB target groups and health checks,
* private subnets + security groups,
* a straightforward path from "CI built an image" -> "run that image".

EKS would have been cluster overhead for one small service; EC2 would have added OS management.

**Why ALB**  
ALB gives us:

* a stable HTTP origin for CloudFront,
* `/healthz` health checks,
* the ability to lock inbound to "only CloudFront" using the AWS-managed prefix list,
* clean mapping from URL -> ECS task.

**Why CloudFront**  
CloudFront sits in front because the platform task required the service to be reachable at a CloudFront URL. It also gives us a single public endpoint, future WAF, and the option to keep the ALB effectively private.

**S3 read model**  
Right now we read "the latest object under a prefix". That matches how the sample logs are written. We added pagination so it will not break past 1,000 objects. Extending it to "latest N" or "since timestamp" is the next natural step.

---

## 5. Limitations / next steps

* Checkov is in the repo but we are not failing the pipeline on its findings (time-boxed).
* No static analysis (Ruff/Bandit/SonarQube) in CI yet — should be added.
* Terraform modules are not versioned — in a real setup we would tag `terraform_modules/` and pin envs to versions.
* No authentication on the HTTP API — `/analyze` is open. In a real environment this would sit behind Cognito, an API key, or at least CloudFront signed headers.
* Alerting is local only — we return `{"alert": true}` but do not push to SNS / EventBridge / Slack. Next step would be to publish alerts to SNS so ops gets notified.
* Single environment shown — we wired `prod` to keep it simple. Normally we would have `dev/stage/prod` workspaces or separate env folders sharing the same modules.
* Image/security scanning not enforced — we build and push to ECR, but we are not failing the pipeline on image scan / Checkov yet.
* Modules not versioned — `terraform_modules/` is used from source; in a team setup we would tag module releases and pin envs to those tags.
