#!/bin/bash

N1=$'\n'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -n "(SSL) Creating cert directory: "

OUTPUT=$(rm -rf /root/certs && mkdir /root/certs >/dev/null 2>&1)

if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error creating the certs directory."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi



openssl genrsa > privkey.pem
openssl req -new -x509 -key privkey.pem > fullchain.pem

