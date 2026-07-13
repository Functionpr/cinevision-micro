#!/bin/sh
set -eu

bundle_url="${AWS_RDS_CA_BUNDLE_URL:-https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem}"
truststore="${JAVA_HOME}/lib/security/cacerts"
storepass="${JAVA_CACERTS_PASSWORD:-changeit}"
workdir="$(mktemp -d)"

cleanup() {
  rm -rf "$workdir"
}
trap cleanup EXIT

wget -q -O "$workdir/global-bundle.pem" "$bundle_url"

awk -v dir="$workdir" '
  /-----BEGIN CERTIFICATE-----/ { n++ }
  n > 0 { print > (dir "/rds-ca-" n ".pem") }
' "$workdir/global-bundle.pem"

for cert in "$workdir"/rds-ca-*.pem; do
  [ -s "$cert" ] || continue
  alias="$(
    openssl x509 -noout -subject -in "$cert" |
      sed -E 's/^subject= *//; s/.*CN *= *//; s/,.*//; s/[^A-Za-z0-9._-]/-/g' |
      tr '[:upper:]' '[:lower:]'
  )"
  [ -n "$alias" ] || alias="certificate-$(basename "$cert" .pem)"

  keytool -importcert \
    -trustcacerts \
    -noprompt \
    -alias "aws-rds-${alias}" \
    -file "$cert" \
    -keystore "$truststore" \
    -storepass "$storepass"
done
