FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
RUN microdnf install -y skopeo jq python3 python3-pip
RUN . /cachi2/cachi2.env && pip3 install /cachi2/output/deps/pip/ruamel.yaml-0.17.9.tar.gz

COPY bundle-hack .
COPY cloud-resource-operator/bundles/1.1.5/manifests /manifests/
COPY cloud-resource-operator/bundles/1.1.5/metadata /metadata/
COPY cloud-resource-operator/LICENSE licenses/

RUN chmod +x ./update_bundle.sh
RUN ./update_bundle.sh

# Core bundle labels.
LABEL operators.operatorframework.io.bundle.mediatype.v1=registry+v1
LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
LABEL operators.operatorframework.io.bundle.package.v1=rhmi-cloud-resources
LABEL operators.operatorframework.io.bundle.channels.v1=rhmi
LABEL operators.operatorframework.io.bundle.channel.default.v1=rhmi
LABEL operators.operatorframework.io/builder=operator-sdk-v1.13.0+git
LABEL operators.operatorframework.io/project_layout=go.kubebuilder.io/v2

USER 1001