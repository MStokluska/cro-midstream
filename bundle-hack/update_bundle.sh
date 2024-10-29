#!/usr/bin/env bash

export CLOUD_RESOURCE_OPERATOR_IMAGE_PULLSPEC="quay.io/integreatly/cloud-resource-operator:v1.1.4"

export CSV_FILE=/manifests/gatekeeper-operator.clusterserviceversion.yaml

sed -e "s|quay.io/integreatly/cloud-resource-operator:v.*|\"${CLOUD_RESOURCE_OPERATOR_IMAGE_PULLSPEC}\"|g" \
	"${CSV_FILE}"

export AMD64_BUILT=$(skopeo inspect --raw docker://${CLOUD_RESOURCE_OPERATOR_IMAGE_PULLSPEC} | jq -e '.manifests[] | select(.platform.architecture=="amd64")')
export ARM64_BUILT=$(skopeo inspect --raw docker://${CLOUD_RESOURCE_OPERATOR_IMAGE_PULLSPEC} | jq -e '.manifests[] | select(.platform.architecture=="arm64")')
export PPC64LE_BUILT=$(skopeo inspect --raw docker://${CLOUD_RESOURCE_OPERATOR_IMAGE_PULLSPEC} | jq -e '.manifests[] | select(.platform.architecture=="ppc64le")')
export S390X_BUILT=$(skopeo inspect --raw docker://${CLOUD_RESOURCE_OPERATOR_IMAGE_PULLSPEC} | jq -e '.manifests[] | select(.platform.architecture=="s390x")')

export EPOC_TIMESTAMP=$(date +%s)
# time for some direct modifications to the csv
python3 - << CSV_UPDATE
import os
from collections import OrderedDict
from sys import exit as sys_exit
from datetime import datetime
from ruamel.yaml import YAML
yaml = YAML()
def load_manifest(pathn):
   if not pathn.endswith(".yaml"):
      return None
   try:
      with open(pathn, "r") as f:
         return yaml.load(f)
   except FileNotFoundError:
      print("File can not found")
      exit(2)

def dump_manifest(pathn, manifest):
   with open(pathn, "w") as f:
      yaml.dump(manifest, f)
   return
timestamp = int(os.getenv('EPOC_TIMESTAMP'))
datetime_time = datetime.fromtimestamp(timestamp)
cro_csv = load_manifest(os.getenv('CSV_FILE'))
# Add arch and os support labels
cro_csv['metadata']['labels'] = cro_csv['metadata'].get('labels', {})
if os.getenv('AMD64_BUILT'):
	cro_csv['metadata']['labels']['operatorframework.io/arch.amd64'] = 'supported'
if os.getenv('ARM64_BUILT'):
	cro_csv['metadata']['labels']['operatorframework.io/arch.arm64'] = 'supported'
if os.getenv('PPC64LE_BUILT'):
	cro_csv['metadata']['labels']['operatorframework.io/arch.ppc64le'] = 'supported'
if os.getenv('S390X_BUILT'):
	cro_csv['metadata']['labels']['operatorframework.io/arch.s390x'] = 'supported'
cro_csv['metadata']['labels']['operatorframework.io/os.linux'] = 'supported'
# Ensure that the created timestamp is current
cro_csv['metadata']['annotations']['createdAt'] = datetime_time.strftime('%d %b %Y, %H:%M')
# Add annotations for the openshift operator features
cro_csv['metadata']['annotations']['features.operators.openshift.io/disconnected'] = 'true'
cro_csv['metadata']['annotations']['features.operators.openshift.io/fips-compliant'] = 'false'
cro_csv['metadata']['annotations']['features.operators.openshift.io/proxy-aware'] = 'false'
cro_csv['metadata']['annotations']['features.operators.openshift.io/tls-profiles'] = 'false'
cro_csv['metadata']['annotations']['features.operators.openshift.io/token-auth-aws'] = 'false'
cro_csv['metadata']['annotations']['features.operators.openshift.io/token-auth-azure'] = 'false'
cro_csv['metadata']['annotations']['features.operators.openshift.io/token-auth-gcp'] = 'false'

dump_manifest(os.getenv('CSV_FILE'), gatekeeper_csv)
CSV_UPDATE

cat $CSV_FILE