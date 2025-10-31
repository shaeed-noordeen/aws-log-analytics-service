AWS Log Analytics Service

A small service that reads the latest JSON Lines (.jsonl) log file from S3, counts ERRORs, groups them by service, and returns a JSON summary.

It exposes the same logic in three ways:

CLI – for developers / CI to run the analyzer locally  
HTTP API (FastAPI) – for ECS / ALB / CloudFront  
ECS Fargate service – production-ish, fronted by CloudFront → ALB → ECS

Infra is provisioned with Terraform (`terraform/`) and assumes AWS + an external DNS entry (we used GoDaddy) for the ALB origin.

## 1. Architecture

**Ingress path**  
Client → CloudFront (public HTTPS) → ALB (CloudFront-only SG) → ECS Fargate task → FastAPI app → S3

**Why this shape?**

- CloudFront gives us the public endpoint, TLS, WAF, and lets us hide the ALB.  
- ALB gives us ECS integration and health checks on `/healthz`.  
- ECS Fargate runs an always-on container with uvicorn on port 8080.  
- S3 is the source of truth for logs; we always read the latest object under a given prefix.

Because the ALB security group only allows CloudFront origin-facing addresses, you cannot curl the ALB DNS from the internet — that’s intentional. Use the CloudFront URL.

## 2. Run it locally

### 2.1 CLI

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -e .

# Analyze local file
analyze --file testdata/sample.jsonl

# Analyze latest S3 object
AWS_REGION=eu-north-1 \
analyze --bucket devops-assignment-logs-430957 \
        --prefix 2025-09-15T12-00.jsonl \
        --threshold 3
```

### 2.2 HTTP (uvicorn)

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -e .
uvicorn app.http_server:app --host 0.0.0.0 --port 8080
```

Endpoints:

- `GET /healthz`
- `GET /analyze?bucket=<bucket>&prefix=<key-or-prefix>&threshold=3`

### 2.3 Docker

```bash
docker build -t log-analyzer:local -f docker/Dockerfile .
docker run --rm -p 8080:8080 \
  -e AWS_REGION=eu-north-1 \
  -e AWS_ACCESS_KEY_ID=... \
  -e AWS_SECRET_ACCESS_KEY=... \
  log-analyzer:local
```

## 3. Deploying to AWS (Terraform)

Everything is under `terraform/`.

**Prereqs (manual / once, outside Terraform):**

- S3 bucket for Terraform state  
- DynamoDB table for Terraform locks  
- ACM cert for GoDaddy Domain in the same region as the ALB  
- Public DNS CNAME in GoDaddy.

**Deploy:**

```bash
cd terraform/envs/prod
terraform init
terraform plan  -var="image_tag=<your-ecr-tag>"
terraform apply -var="image_tag=<your-ecr-tag>"
```

**Get the URL:**

```bash
terraform -chdir=terraform/envs/prod output -raw cloudfront_domain_name
```

Then test:

```bash
curl "https://<CLOUDFRONT>/healthz"
curl "https://<CLOUDFRONT>/analyze?bucket=<bucket_name>&prefix=<prefix>&threshold=<number>"
```

## 4. CI/CD (high level)

1. Build + test the Python app.  
2. Build Docker image, tag with commit SHA.  
3. Push to ECR.  
4. Run `terraform plan/apply` in `terraform/envs/prod` with that image tag.  
5. Smoke test through CloudFront on `/healthz` and `/analyze`.

Pipelines assume:

- AWS role is already set up (OIDC / short-lived credentials).  
- ECR repository exists.  
- The GoDaddy CNAME is already created.

## 5. Design decisions

- **Single repo**: app, infra, Docker, CI/CD live together to keep the take-home easy to review.  
- **Edge-first**: public traffic comes in through CloudFront; ALB is not directly exposed.  
- **Vanity origin**: `alb-origin.shaeed.co.uk` keeps CloudFront → ALB TLS/SNI aligned with the ACM cert, avoiding 502 errors.  
- **Shared analyzer**: CLI and HTTP use the same function, so we only test the core logic once.  
- **S3 “latest” strategy**: list S3 under the prefix, pick the object with the newest `LastModified`, analyze only that one.

## 6. Limitations / “If I had more time”

- **Modules aren’t reusable yet**: Terraform modules in `terraform/modules/` are tailored to this service. I’d split them into a separate repo with versioned releases.  
- **External DNS dependency**: Because DNS is managed in GoDaddy, Terraform can’t create `alb-origin.shaeed.co.uk`. Moving DNS to Route 53 would make this declarative.
- **CLI distribution**: Today you clone + `pip install -e .`. Better tooling would publish a wheel to an internal PyPI.  
- **Single environment**: Everything lives under `terraform/envs/prod`. To add dev/stg, we’d introduce additional env folders or parameterize more aggressively.  
- **Auth is implicit**: We rely on CloudFront + security groups; there’s no API key or IAM auth on the HTTP layer.  
- **Basic deploy strategy**: ECS runs the service, but there’s no autoscaling policy or blue/green rollout.

## 7. Repo layout

```
.
├── app/                 # FastAPI app, analyzer logic, CLI entrypoint
├── docker/              # Dockerfile(s) for local + ECS
├── terraform/
│   ├── modules/         # network, alb, ecs_service, cloudfront
│   └── envs/
│       └── prod/        # actual environment wiring
├── testdata/            # sample .jsonl logs
├── .github/workflows/   # CI/CD pipelines
├── setup.py             # enables `pip install -e .`
└── README.md
```
