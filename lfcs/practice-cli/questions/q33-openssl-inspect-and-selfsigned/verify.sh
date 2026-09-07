#!/bin/bash
# Q33 openssl: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

DIR="$COURSE_DIR/33"
CRT="$DIR/server.crt"
ANS="$DIR/answer.txt"
LABC=/etc/ssl/lab/lab.crt
LABK=/etc/ssl/lab/lab.key

echo "Checking the scenario is still in place..."
check "the supplied certificate is present at $CRT" test -s "$CRT"
if [[ ! -s "$CRT" ]]; then
  echo "  Without the supplied certificate the report cannot be graded. Run setup again."
  summary
  exit $?
fi

CN=$(openssl x509 -in "$CRT" -noout -subject 2>/dev/null | sed -E 's/.*CN[[:space:]]*=[[:space:]]*//; s/[[:space:]]*$//')
END=$(openssl x509 -in "$CRT" -noout -enddate 2>/dev/null | cut -d= -f2-)
ANSTXT=$(cat "$ANS" 2>/dev/null)

echo "Checking the report..."
check "answer.txt exists at $ANS" test -s "$ANS"
check_contains "answer.txt names the common name $CN" "$CN" "$ANSTXT"
check_contains "answer.txt carries the notAfter date" "$END" "$ANSTXT"

echo "Checking the new certificate..."
check "lab.crt exists at $LABC" test -s "$LABC"
LABCN=$(openssl x509 -in "$LABC" -noout -subject 2>/dev/null | sed -E 's/.*CN[[:space:]]*=[[:space:]]*//; s/[[:space:]]*$//')
check_eq "the new certificate's common name is lab.local" "lab.local" "$LABCN"

BITS=$(openssl x509 -in "$LABC" -noout -text 2>/dev/null | sed -nE 's/.*Public-Key: \(([0-9]+) bit\).*/\1/p' | head -1)
check_eq "the certificate carries a 2048 bit RSA key" "2048" "$BITS"

NB=$(openssl x509 -in "$LABC" -noout -startdate 2>/dev/null | cut -d= -f2-)
NA=$(openssl x509 -in "$LABC" -noout -enddate 2>/dev/null | cut -d= -f2-)
DAYS=""
if [[ -n "$NB" && -n "$NA" ]]; then
  S=$(date -d "$NB" +%s 2>/dev/null)
  E=$(date -d "$NA" +%s 2>/dev/null)
  [[ -n "$S" && -n "$E" ]] && DAYS=$(( (E - S) / 86400 ))
fi
VALIDITY=no
[[ "$DAYS" =~ ^[0-9]+$ ]] && (( DAYS >= 364 && DAYS <= 366 )) && VALIDITY=yes
check_eq "the certificate is valid for 365 days (measured ${DAYS:-none})" "yes" "$VALIDITY"

echo "Checking the private key..."
check "lab.key exists at $LABK" test -s "$LABK"
check_eq "lab.key is mode 600" "600" "$(stat -c %a "$LABK" 2>/dev/null)"
check_eq "lab.key is owned by root" "root" "$(stat -c %U "$LABK" 2>/dev/null)"
check "lab.key carries no passphrase" openssl rsa -in "$LABK" -noout -modulus -passin pass:

CMOD=$(openssl x509 -in "$LABC" -noout -modulus 2>/dev/null | openssl sha256 2>/dev/null | awk '{print $NF}')
KMOD=$(openssl rsa -in "$LABK" -noout -modulus -passin pass: 2>/dev/null | openssl sha256 2>/dev/null | awk '{print $NF}')
MATCH=no
[[ -n "$CMOD" && "$CMOD" == "$KMOD" ]] && MATCH=yes
check_eq "the key and the certificate share one modulus" "yes" "$MATCH"

echo "Checking the files are where a service finds them after a reboot..."
check_persisted "the certificate is stored under /etc/ssl/lab" \
  '^-----BEGIN CERTIFICATE-----' "$LABC"
check_persisted "the private key is stored under /etc/ssl/lab" \
  'PRIVATE KEY-----' "$LABK"

summary
