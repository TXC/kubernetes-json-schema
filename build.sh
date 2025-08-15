#!/bin/bash

# DEBUG
#set -xe
set -e

# This script uses openapi2jsonschema to generate a set of JSON schemas for
# the specified Kubernetes versions in three different flavours:
#
#   X.Y.Z - URL referenced based on the specified GitHub repository
#   X.Y.Z-standalone - de-referenced schemas, more useful as standalone documents
#   X.Y.Z-standalone-strict - de-referenced schemas, more useful as standalone documents, additionalProperties disallowed
#   X.Y.Z-local - relative references, useful to avoid the network dependency

declare -a arr=(master)

outputdir="output"
binary="openapi2jsonschema"
lowestver="v1.5.0"

###


URL="https://api.github.com/repos/kubernetes/kubernetes/releases?per_page=100"
while [ "$URL" ]; do
  #RESP=$(curl -i -Ss "$URL")
  RESP=$(curl -i -Ss -H "Authorization: Bearer ${GITHUB_TOKEN}" "${URL}")
  HEADERS=$(echo "$RESP" | sed '/^\r$/q')
  URL=$(echo "$HEADERS" | sed -n -E 's/Link:.*<(.*?)>; rel="next".*/\1/Ip')
  echo "$RESP" | sed '1,/^\r$/d' | jq -r '.[] | select(.prerelease == false) | .tag_name' | sort -V | \
  while read -r line; do
    if [ "$(printf '%s\n' "$lowestver" "$line" | sort -V | head -n1)" = "$lowestver" ]; then
      continue;
    fi;
    arr+=("$line")
  done
done

if [ ! -d "${outputdir}" ]; then
  mkdir -p "${outputdir}"
fi

for version in "${arr[@]}"
do
  echo -n "Processing ${version}..."
  schema=https://raw.githubusercontent.com/kubernetes/kubernetes/${version}/api/openapi-spec/swagger.json
  prefix=https://txc.github.io/kubernetes-json-schema/${version}/_definitions.json

  $binary -o "${outputdir}/${version}" --expanded --kubernetes --strict --prefix "${prefix}" "${schema}"
  #$binary -o "${outputdir}/${version}-standalone-strict" --expanded --kubernetes --stand-alone --strict "${schema}"
  #$binary -o "${outputdir}/${version}-standalone" --expanded --kubernetes --stand-alone "${schema}"
  #$binary -o "${outputdir}/${version}-local" --expanded --kubernetes "${schema}"
  #$binary -o "${outputdir}/${version}" --expanded --kubernetes --prefix "${prefix}" "${schema}"
  #$binary -o "${outputdir}/${version}-standalone-strict" --kubernetes --stand-alone --strict "${schema}"
  #$binary -o "${outputdir}/${version}-standalone" --kubernetes --stand-alone "${schema}"
  #$binary -o "${outputdir}/${version}-local" --kubernetes "${schema}"
  #$binary -o "${outputdir}/${version}" --kubernetes --prefix "${prefix}" "${schema}"

  echo "Done."
  exit 0;
done
