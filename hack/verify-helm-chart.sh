#!/bin/bash

# Copyright 2019 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

readonly PKG_ROOT="$(git rev-parse --show-toplevel)"

function get_image_from_helm_chart() {
  local -r image_name="${1}"
  image_repository="$(cat ${PKG_ROOT}/charts/latest/azuredisk-csi-driver/values.yaml | yq -r .image.${image_name}.repository)"
  image_tag="$(cat ${PKG_ROOT}/charts/latest/azuredisk-csi-driver/values.yaml | yq -r .image.${image_name}.tag)"
  echo "${image_repository}:${image_tag}"
}

function validate_image() {
  local -r expected_image="${1}"
  local -r image="${2}"

  if [[ "${expected_image}" != "${image}" ]]; then
    echo "Expected ${expected_image}, but got ${image} in helm chart"
    exit 1
  fi
}

echo "Comparing image version between helm chart and manifests in deploy folder"

# jq-equivalent for yaml
pip install yq

# Extract images from csi-azuredisk-controller.yaml
expected_csi_provisioner_image="$(cat ${PKG_ROOT}/deploy/csi-azuredisk-controller.yaml | yq -r .spec.template.spec.containers[0].image | head -n 1)"
expected_csi_attacher_image="$(cat ${PKG_ROOT}/deploy/csi-azuredisk-controller.yaml | yq -r .spec.template.spec.containers[1].image | head -n 1)"
expected_cluster_driver_registrar_image="$(cat ${PKG_ROOT}/deploy/csi-azuredisk-controller.yaml | yq -r .spec.template.spec.containers[2].image | head -n 1)"
expected_csi_snapshotter_image="$(cat ${PKG_ROOT}/deploy/csi-azuredisk-controller.yaml | yq -r .spec.template.spec.containers[3].image | head -n 1)"
expected_liveness_probe_image="$(cat ${PKG_ROOT}/deploy/csi-azuredisk-controller.yaml | yq -r .spec.template.spec.containers[4].image | head -n 1)"
expected_azuredisk_image="$(cat ${PKG_ROOT}/deploy/csi-azuredisk-controller.yaml | yq -r .spec.template.spec.containers[5].image | head -n 1)"

csi_provisioner_image="$(get_image_from_helm_chart "csiProvisioner")"
validate_image "${expected_csi_provisioner_image}" "${csi_provisioner_image}"

csi_attacher_image="$(get_image_from_helm_chart "csiAttacher")"
validate_image "${expected_csi_attacher_image}" "${csi_attacher_image}"

cluster_driver_registrar_image="$(get_image_from_helm_chart "clusterDriverRegistrar")"
validate_image "${expected_cluster_driver_registrar_image}" "${cluster_driver_registrar_image}"

csi_snapshotter_image="$(get_image_from_helm_chart "csiSnapshotter")"
validate_image "${expected_csi_snapshotter_image}" "${csi_snapshotter_image}"

liveness_probe_image="$(get_image_from_helm_chart "livenessProbe")"
validate_image "${expected_liveness_probe_image}" "${liveness_probe_image}"

azuredisk_image="$(get_image_from_helm_chart "azuredisk")"
validate_image "${expected_azuredisk_image}" "${azuredisk_image}"

# Extract images from csi-azuredisk-node.yaml
expected_liveness_probe_image="$(cat ${PKG_ROOT}/deploy/csi-azuredisk-node.yaml | yq -r .spec.template.spec.containers[0].image | head -n 1)"
expected_node_driver_registrar="$(cat ${PKG_ROOT}/deploy/csi-azuredisk-node.yaml | yq -r .spec.template.spec.containers[1].image | head -n 1)"
expected_azuredisk_image="$(cat ${PKG_ROOT}/deploy/csi-azuredisk-node.yaml | yq -r .spec.template.spec.containers[2].image | head -n 1)"

validate_image "${expected_liveness_probe_image}" "${liveness_probe_image}"

node_driver_registrar="$(get_image_from_helm_chart "nodeDriverRegistrar")"
validate_image "${expected_node_driver_registrar}" "${node_driver_registrar}"

validate_image "${expected_azuredisk_image}" "${azuredisk_image}"

echo "Images in deploy/ matches those in the latest helm chart."
