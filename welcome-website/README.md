# Welcome Website Service

This is the simple “Welcome World” app for the platform assignment. It proves the infra pattern:
**ECS Fargate → ALB → CloudFront** and reuses the same Terraform modules as the log analyzer service. :contentReference[oaicite:0]{index=0}

Public endpoint (current deploy):

```text
https://d1u3siethdbwrx.cloudfront.net/
```

---

## 1. Run locally

### Docker

```bash
cd welcome-website/app
docker build -t welcome-website:local .
docker run --rm -p 8080:80 welcome-website:local
```

Then open:

```text
http://localhost:8080
```

---

## 2. Deploy (Terraform)

Infra for this service is in:

```text
welcome-website/terraform/envs/welcome
```

Deploy:

```bash
terraform -chdir=welcome-website/terraform/envs/welcome init
terraform -chdir=welcome-website/terraform/envs/welcome apply -auto-approve \
  -var="image_tag=<your-ecr-image-tag>"
```

This creates:

1. VPC/subnets/routing
2. ECS Fargate service running the container
3. ALB in front (health + origin)
4. CloudFront in front of the ALB, so it’s publicly reachable. 

---

## 3. Test

Local:

```bash
curl http://localhost:8080
```

Deployed:

```bash
curl https://d1u3siethdbwrx.cloudfront.net/
```

---

## 4. Design decisions

**ECS Fargate**
We needed to run a small HTTP container in AWS without managing EC2 or a Kubernetes control plane. Fargate runs the container, keeps it alive, and integrates directly with an ALB. EC2 would add OS/patching; EKS would be overkill for a single static page. 

**ALB**
ALB gives CloudFront a stable origin, health checks, and a place to lock inbound traffic to CloudFront only.

**CloudFront**
The brief required the app to be exposed publicly through CloudFront, so CloudFront is the public entrypoint. It also keeps this service consistent with the log analyzer service. 

**Shared modules**
Using the existing network/iam/ecs/alb/cloudfront modules shows they can support more than one workload without rewriting infra.

---

## 5. Limitations / next steps

* **No custom domain** – we’re using the generated CloudFront URL; we could have added a domain and ACM validation if this were going to users.
* **No auth / WAF** – page is public; for production we’d normally add WAF rules or origin access.
* **No alarms / SNS** – the stretch items (SNS notifications, CloudWatch alarms) were left out to keep this focused. 
* **Single environment** – only `welcome` is shown; adding `dev` / `staging` with the same modules would be straightforward.

```
::contentReference[oaicite:5]{index=5}
```
