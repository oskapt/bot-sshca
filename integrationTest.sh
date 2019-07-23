#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Unit tests first
go test ./...

# Some colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# A function used to indent the log output from the tests
indent() { sed 's/^/    /'; }

cd tests/single-environment/
source env.sh
../reset.sh
cat keybaseca.config.gen | envsubst > keybaseca.config
echo "Building containers..."
docker-compose build 2>&1 > /dev/null
echo "Running integration tests..."
docker-compose up -d

docker logs kssh -f | indent
TEST_EXIT_CODE=`docker wait kssh`

if [ -z ${TEST_EXIT_CODE+x} ] || [ "$TEST_EXIT_CODE" -ne 0 ] ; then
  printf "${RED}Single Environment Tests Failed${NC} - Exit Code: $TEST_EXIT_CODE\n"
else
  printf "${GREEN}Single Environment Mode Tests Passed${NC}\n"
fi

docker-compose stop 2>&1 > /dev/null
docker-compose kill 2>&1 > /dev/null
docker-compose rm -f

cd ../multi-environment/
source env.sh
../reset.sh
cat keybaseca.config.gen | envsubst > keybaseca.config
echo "Building containers..."
docker-compose build 2>&1 > /dev/null
echo "Running integration tests..."
docker-compose up -d

docker logs -f kssh | indent
TEST_EXIT_CODE=`docker wait kssh`

if [ -z ${TEST_EXIT_CODE+x} ] || [ "$TEST_EXIT_CODE" -ne 0 ] ; then
  printf "${RED}Multi-Environment Tests Failed${NC} - Exit Code: $TEST_EXIT_CODE\n"
else
  printf "${GREEN}Multi-Environment Tests Passed${NC}\n"
fi

docker-compose stop 2>&1 > /dev/null
docker-compose kill 2>&1 > /dev/null
docker-compose rm -f

../reset.sh
