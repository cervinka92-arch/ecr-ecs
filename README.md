# Ukol 8 - Docker image na ECR + ECS Fargate (Terraform + GitHub Actions)

Navazuje na [ukol7](../ukol7). Vlastni `nginx:alpine` image s vlastnim `index.html`
se builduje, publikuje do AWS ECR a nasazuje do ECS Fargate za Application Load
Balancerem. Registry i zbytek infrastruktury vytvari Terraform, autentizace
pipeline do AWS jde pres GitHub OIDC (zadne dlouhodobe AWS klice v secrets).

## Cast 1 - Docker image + publikace do ECR (10 bodu)

- [Dockerfile](Dockerfile) - `FROM nginx:alpine`, `COPY index.html`
- [index.html](index.html) - staticka stranka zobrazena kontejnerem
- Pipeline builduje image a pushuje ho do ECR (kroky *Build and push Docker
  image to ECR* v [.github/workflows/deploy.yml](.github/workflows/deploy.yml))

## Cast 2 (bonus) - Infrastruktura Terraformem (5 bodu)

Terraform vychazi z [ukol7](../ukol7/main.tf) s temito zmenami:

| Zmena | Kde |
|---|---|
| Novy `aws_ecr_repository.app` | [main.tf](main.tf) |
| Task definition ted odkazuje na ECR repo (ne na `nginx:alpine` z Docker Hub) | `aws_ecs_task_definition.nginx` v [main.tf](main.tf) |
| Novy `aws_iam_openid_connect_provider.github` + `aws_iam_role.github_actions` - IAM role narokovana konkretnimu git repozitari (`sub = repo:<owner>/<repo>:*`), kterou GitHub Actions pouziva pro autentizaci do AWS | [main.tf](main.tf) |
| Puvodni `aws_iam_role.ecs_task_execution` zustava - je to role, kterou pouziva samotny ECS task jako svoji `execution_role_arn` (assumuje ji sluzba `ecs-tasks.amazonaws.com`, ne GitHub) | [main.tf](main.tf) |

Pipeline (viz [deploy.yml](.github/workflows/deploy.yml)) pri push do `main`:

1. `terraform apply -target=aws_ecr_repository.app` - vytvori jen ECR registry
2. Build & push docker image do tohoto ECR repository (tag = commit SHA + `latest`)
3. `terraform apply -var="image_tag=<sha>"` - plny apply, vytvori zbytek
   infrastruktury (ALB, ECS cluster/service, IAM, CloudWatch) a task definition
   uz odkazuje primo na prave pushnuty image

## Priprava pred prvnim spustenim

### 1. GitHub repozitar

Repozitar: https://github.com/cervinka92-arch/ecr-ecs. Nahrajte do nej obsah
teto slozky.

### 2. `github_repo` v terraform.tfvars

Uz je nastaveno na `cervinka92-arch/ecr-ecs` v [terraform.tfvars](terraform.tfvars).

### 3. Bootstrap OIDC role a ECR (lokalne, jednorazove)

GitHub Actions se do AWS prihlasuje pomoci IAM role, ktera ale jeste
neexistuje - musi ji tedy nekdo vytvorit prvni, s existujicimi AWS creds
(stejny AWS ucet jako v ukolu 7):

```bash
terraform init
terraform apply -target=aws_iam_openid_connect_provider.github \
                 -target=aws_iam_role.github_actions \
                 -target=aws_iam_role_policy_attachment.github_actions_admin \
                 -target=aws_ecr_repository.app
```

Po dokonceni si vypiste ARN role:

```bash
terraform output github_actions_role_arn
```

### 4. Nastavte GitHub repository variable

V repozitari: **Settings -> Secrets and variables -> Actions -> Variables tab
-> New repository variable**

| Variable | Hodnota |
|---|---|
| `AWS_ROLE_ARN` | ARN z kroku 3 (`terraform output github_actions_role_arn`) |

Zadne AWS klice (access key / secret key) uz pipeline nepotrebuje.

### 5. Push do `main`

Push spusti pipeline, ktera dokonci zbytek infrastruktury a nasadi image
(viz kroky vyse).

## Vystup po nasazeni

```bash
terraform output load_balancer_url
terraform output ecr_repository_url
```

## Test dostupnosti

```bash
curl http://<alb-dns-name>
```

Pri uspechu vrati vlastni `index.html` (HTTP 200).

## Vycisteni

```bash
terraform destroy -auto-approve
```

> S3 bucket pro Terraform state se maze rucne (Terraform ho nevytvarel).
> ECR repository ma `force_delete = true`, takze se smaze i s obsazenymi
> images.
