#!/bin/bash

N1=$'\n'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

openssl genrsa > privkey.pem
openssl req -new -x509 -key privkey.pem > fullchain.pem

