#!/usr/bin/env bash
#
# Bootstrap-Phase 0 für Kickwise GCP-Setup.
# Einmalig auszuführen, bevor `terraform init` zum ersten Mal läuft.
#
# Erwartet:
# - gcloud CLI authentifiziert
# - GCP-Projekt 'kickwise-prod' existiert
# - Billing-Account ist mit dem Projekt verknüpft (manuell in Console)
#
set -euo pipefail

PROJECT_ID="kickwise-prod"
REGION="europe-west3"
TF_STATE_BUCKET="${PROJECT_ID}-tf-state"
BOOTSTRAP_SA_NAME="terraform-bootstrap"
BOOTSTRAP_SA_EMAIL="${BOOTSTRAP_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_PATH="${HOME}/.gcp/kickwise-terraform-bootstrap.json"

echo "==> Aktives Projekt setzen: ${PROJECT_ID}"
gcloud config set project "${PROJECT_ID}"

echo "==> GCP-APIs aktivieren"
gcloud services enable \
  run.googleapis.com \
  firestore.googleapis.com \
  bigquery.googleapis.com \
  cloudbuild.googleapis.com \
  cloudscheduler.googleapis.com \
  secretmanager.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  compute.googleapis.com \
  artifactregistry.googleapis.com \
  storage.googleapis.com \
  serviceusage.googleapis.com \
  --project="${PROJECT_ID}"

echo "==> Terraform-State-Bucket erstellen: gs://${TF_STATE_BUCKET}"
if gcloud storage buckets describe "gs://${TF_STATE_BUCKET}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
  echo "    (Bucket existiert bereits, wird übersprungen)"
else
  gcloud storage buckets create "gs://${TF_STATE_BUCKET}" \
    --project="${PROJECT_ID}" \
    --location="${REGION}" \
    --uniform-bucket-level-access \
    --public-access-prevention
fi

echo "==> Versioning auf State-Bucket aktivieren"
gcloud storage buckets update "gs://${TF_STATE_BUCKET}" --versioning

echo "==> Lifecycle-Policy auf State-Bucket"
LIFECYCLE_FILE="$(mktemp)"
cat <<'EOF' > "${LIFECYCLE_FILE}"
{
  "lifecycle": {
    "rule": [
      {
        "action": { "type": "Delete" },
        "condition": { "numNewerVersions": 10, "daysSinceNoncurrentTime": 90 }
      }
    ]
  }
}
EOF
gcloud storage buckets update "gs://${TF_STATE_BUCKET}" --lifecycle-file="${LIFECYCLE_FILE}"
rm "${LIFECYCLE_FILE}"

echo "==> Bootstrap-Service-Account anlegen: ${BOOTSTRAP_SA_EMAIL}"
if gcloud iam service-accounts describe "${BOOTSTRAP_SA_EMAIL}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
  echo "    (SA existiert bereits, wird übersprungen)"
else
  gcloud iam service-accounts create "${BOOTSTRAP_SA_NAME}" \
    --display-name="Terraform Bootstrap" \
    --project="${PROJECT_ID}"
fi

echo "==> Rollen an Bootstrap-SA vergeben"
for role in roles/editor roles/iam.securityAdmin roles/storage.admin roles/resourcemanager.projectIamAdmin; do
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${BOOTSTRAP_SA_EMAIL}" \
    --role="${role}" \
    --condition=None \
    --quiet
done

echo "==> SA-Key generieren: ${KEY_PATH}"
mkdir -p "$(dirname "${KEY_PATH}")"
if [ -f "${KEY_PATH}" ]; then
  echo "    (Key existiert bereits, wird übersprungen — bei Bedarf manuell löschen und neu rotieren)"
else
  gcloud iam service-accounts keys create "${KEY_PATH}" \
    --iam-account="${BOOTSTRAP_SA_EMAIL}" \
    --project="${PROJECT_ID}"
  chmod 600 "${KEY_PATH}"
fi

echo ""
echo "==> Bootstrap abgeschlossen."
echo ""
echo "    State-Bucket : gs://${TF_STATE_BUCKET}"
echo "    Bootstrap-SA : ${BOOTSTRAP_SA_EMAIL}"
echo "    SA-Key       : ${KEY_PATH}"
echo ""
echo "    Nächste Schritte:"
echo "      export GOOGLE_APPLICATION_CREDENTIALS='${KEY_PATH}'"
echo "      cd terraform"
echo "      terraform init"
echo "      terraform plan -var-file=environments/prod.tfvars"
echo ""
