# Operations Runbook

**Live environment:** https://receipts.buechertausch.click  
**Cluster:** `ascom-receipts-eks` · eu-north-1  
**Grafana:** https://grafana.receipts.buechertausch.click

---

## Access

```bash
# Configure kubectl
aws eks update-kubeconfig --region eu-north-1 --name ascom-receipts-eks

# Verify
kubectl get nodes
kubectl get pods -n receipts
```

---

## Release — Deploy a New Version

**Full flow: code change → production**

```
1. Merge to main in fullstack-microservices-ci-reciepts
2. git tag v1.x.y && git push origin v1.x.y
   → GitHub Actions: test → trivy scan → build → push to Docker Hub
   → Images: u745/receipebook-app:v1.x.y + u745/recipebook-frontend:v1.x.y

3. Update image tags in this repo (gitops)
   edit app/receipts/backend/deployment.yaml   → image: u745/receipebook-app:v1.x.y
   edit app/receipts/frontend/deployment.yaml  → image: u745/recipebook-frontend:v1.x.y
   git commit -m "chore: bump images to v1.x.y"
   git push origin dev

4. ArgoCD detects the change and syncs automatically (self-heal on, ~3 min polling)
   Monitor: kubectl -n receipts rollout status deployment/backend
```

> **Note:** Both deployments use `imagePullPolicy: Always` implicitly with `latest`. When testing with `latest` tags, force a rollout restart to pull the new image:
> ```bash
> kubectl -n receipts rollout restart deployment/backend deployment/frontend
> ```

---

## Rollback

```bash
# Option A: revert the image tag in Git (preferred — keeps Git as source of truth)
git revert HEAD
git push origin dev
# ArgoCD syncs automatically

# Option B: immediate rollback via kubectl (temporary — will be overwritten on next ArgoCD sync)
kubectl -n receipts rollout undo deployment/backend
kubectl -n receipts rollout undo deployment/frontend
```

---

## Scaling

### Horizontal pod scaling

```bash
# Scale frontend (stateless — safe to scale freely)
kubectl -n receipts scale deployment/frontend --replicas=3

# Scale backend (stateless with EFS — safe to scale)
kubectl -n receipts scale deployment/backend --replicas=2
```

> Postgres is a single-replica StatefulSet. For production workloads, migrate to RDS.

### Node group scaling

Edit `desired_size` / `max_size` in `infra/live/aws/dev/dev.tfvars` and apply:

```bash
cd infra/live/aws/dev/aws-eks
terraform apply -var-file=../dev.tfvars
```

---

## Secrets Rotation

Secrets are managed as Bitnami Sealed Secrets. To rotate a value:

```bash
# 1. Fetch the current public key from the cluster
kubeseal --fetch-cert \
  --controller-name=sealed-secrets \
  --controller-namespace=kube-system > pub-cert.pem

# 2. Create a plain Kubernetes Secret manifest (never commit this)
kubectl create secret generic app-secret -n receipts \
  --from-literal=SECRET_KEY='new-django-secret-key' \
  --from-literal=DB_HOST=postgres \
  --from-literal=DB_NAME=receipts \
  --from-literal=DB_USER=receiptsuser \
  --from-literal=DB_PASS='new-db-password' \
  --dry-run=client -o yaml > /tmp/app-secret.yaml

# 3. Seal it
kubeseal --cert pub-cert.pem --format yaml < /tmp/app-secret.yaml \
  > app/receipts/sealed-secrets/app-secret.yaml

# 4. Commit and push — ArgoCD applies the new SealedSecret
git add app/receipts/sealed-secrets/app-secret.yaml
git commit -m "chore: rotate app-secret"
git push origin dev

# 5. Clean up
rm /tmp/app-secret.yaml pub-cert.pem
```

> The Sealed Secrets controller decrypts and recreates the Kubernetes Secret automatically. Pods pick up the new values on next restart (env vars are not hot-reloaded).

---

## Database

### Access psql

```bash
kubectl -n receipts exec -it postgres-0 -- \
  psql -U $POSTGRES_USER -d $POSTGRES_DB
```

### Run a Django management command

```bash
kubectl -n receipts exec -it deploy/backend -- python manage.py shell
kubectl -n receipts exec -it deploy/backend -- python manage.py dbshell
```

### Backup (manual)

```bash
kubectl -n receipts exec postgres-0 -- \
  pg_dump -U $POSTGRES_USER $POSTGRES_DB | gzip > backup_$(date +%Y%m%d).sql.gz
```

> For automated backups in production, configure an RDS instance with automated snapshot retention.

---

## Media Files (EFS)

Recipe photos are stored on the EFS filesystem mounted at `/vol/web/media` in both backend and frontend pods.

```bash
# List uploaded photos
kubectl -n receipts exec deploy/backend -- ls /vol/web/media/uploads/recipe/

# Check EFS PVC status
kubectl -n receipts get pvc media-pvc

# Check EFS volume from frontend (should list the same files)
kubectl -n receipts exec deploy/frontend -- ls /vol/web/media/uploads/recipe/
```

If photos were uploaded before the EFS volume was attached (stored on ephemeral pod disk), they are lost on pod restart. Workaround: re-upload via the Edit recipe form.

---

## Monitoring

### Grafana

Login at https://grafana.receipts.buechertausch.click  
Credentials stored in `app/monitoring/grafana-sealed-secret.yaml`.

Pre-configured data sources:
- **Prometheus** (default) — cluster and application metrics
- **Loki** — pod logs collected by Alloy (DaemonSet)

Useful log queries in Loki:

```logql
# Backend logs
{namespace="receipts", app="backend"}

# Frontend logs
{namespace="receipts", app="frontend"}

# Filter by HTTP 5xx
{namespace="receipts"} |= "500"
```

### Check ArgoCD application health

```bash
kubectl -n argocd get applications
kubectl -n argocd describe application receipts
```

### Useful kubectl commands

```bash
# Pod status
kubectl -n receipts get pods -o wide

# Recent events (useful after a failed deploy)
kubectl -n receipts get events --sort-by='.lastTimestamp' | tail -20

# Backend logs (last 100 lines)
kubectl -n receipts logs deploy/backend --tail=100

# Follow frontend logs
kubectl -n receipts logs deploy/frontend -f

# Describe pod (for crash debugging)
kubectl -n receipts describe pod <pod-name>
```

---

## TLS Certificates

Certificates for `receipts.buechertausch.click` are issued by AWS ACM and attached to the ALB by Terraform. They auto-renew — no manual action required.

The `letsencrypt-prod` ClusterIssuer (cert-manager) is available for in-cluster certificate needs (e.g., adding new Ingresses without ACM).

```bash
# Check cert-manager certificates
kubectl get certificates -A

# Check ClusterIssuer status
kubectl describe clusterissuer letsencrypt-prod
```

---

## Terraform Changes

All Terraform layers are applied in dependency order. Remote state is stored in S3 (`ascom-receipts-app-tfstate-319393fe`), locking via DynamoDB.

```bash
cd infra/live/aws/dev/<layer>
terraform init          # only needed first time or after provider version changes
terraform plan -var-file=../dev.tfvars
terraform apply -var-file=../dev.tfvars
```

Layer dependency order (apply top to bottom, destroy bottom to top):

```
bootstrap → aws-network → aws-iam → aws-eks → aws-addons
```

> `aws-addons` contains: LB Controller, ExternalDNS, EBS/EFS CSI, cert-manager, ArgoCD, ACM certs, Ingresses, EFS filesystem, StorageClass, media-pvc.
