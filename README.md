# kickwise.coach

Infrastruktur-Code für Kickwise (GCP, Terraform).

## Zweck

Definiert alle GCP-Ressourcen für das Projekt `kickwise-prod`:
- BigQuery-Dataset + Tabellen
- Cloud Run Services (Playmaker, Winger)
- Cloud Run Job (Scout) + Cloud Scheduler-Trigger
- Firestore (native)
- Cloud Storage Bucket für Striker (statische Files)
- HTTPS Load Balancer mit Managed Cert
- Secret Manager Secrets (JWT-Secret, etc.)
- Service Accounts pro Workload
- Workload Identity Federation für GitHub Actions

## Voraussetzungen

- `gcloud` CLI authentifiziert (`gcloud auth login`, `gcloud auth application-default login`)
- Terraform ≥ 1.5
- GCP-Projekt `kickwise-prod` mit verknüpftem Billing-Account
- APIs aktiviert und State-Bucket existiert (siehe Bootstrap)

## Bootstrap (einmalig, vor `terraform init`)

Vor dem ersten Terraform-Run müssen ein paar Dinge per `gcloud` vorbereitet werden. Das Skript [`scripts/bootstrap.sh`](scripts/bootstrap.sh) macht das auf einen Schlag:

```bash
cd kickwise.coach
./scripts/bootstrap.sh
```

Das Skript:
1. setzt das aktive Projekt auf `kickwise-prod`
2. aktiviert die nötigen GCP-APIs
3. erstellt den GCS-Bucket `kickwise-prod-tf-state` mit Versioning + Lifecycle
4. legt den Service Account `terraform-bootstrap` an und gibt Rollen
5. lädt einen JSON-Key nach `~/.gcp/kickwise-terraform-bootstrap.json`

**Wichtig**: vor `./scripts/bootstrap.sh` muss der Billing-Account in der GCP Console mit dem Projekt verknüpft sein, sonst scheitern die API-Aktivierungen. Link: <https://console.cloud.google.com/billing/linkedaccount?project=kickwise-prod>

## Terraform-Workflow

```bash
cd terraform

# Lokal mit Bootstrap-SA-Key
export GOOGLE_APPLICATION_CREDENTIALS=$HOME/.gcp/kickwise-terraform-bootstrap.json

terraform init
terraform plan  -var-file=environments/prod.tfvars
terraform apply -var-file=environments/prod.tfvars
```

## Module

| Modul | Zweck |
|-------|-------|
| `bigquery` | Dataset `kickwise_main` + DDL-Apply (Phase-1-Tabellen aktiv, Phase-2+ als kommentierte Stubs) |
| `cloud_run` | Cloud Run Services: Playmaker + Winger |
| `cloud_run_job` | Scout als Cloud Run Job |
| `cloud_scheduler` | Daily-Trigger für Scout |
| `firestore` | Native-Mode-Firestore in `europe-west3` |
| `storage` | Bucket für Striker-Static-Files + CDN-Config |
| `load_balancer` | Globaler HTTPS Load Balancer mit Managed Cert |
| `secrets` | Secret Manager Secrets (JWT-Secret, Winger-internal-Auth, etc.) |
| `service_accounts` | SAs für playmaker, winger, scout, scheduler |
| `workload_identity` | OIDC-Federation für GitHub Actions (Org `juniordev4life`) |

## Naming-Konvention für GCP-Ressourcen

```
kickwise-euw3-{service}-{instance}
```

Beispiele:
- `kickwise-euw3-run-playmaker` (Cloud Run Service)
- `kickwise-euw3-run-winger`
- `kickwise-euw3-job-scout`
- `kickwise-euw3-bucket-striker`
- `kickwise-euw3-sa-playmaker` (Service Account)

`euw3` ist der Region-Code für `europe-west3`.
