#!/bin/sh

make root -e CN=SEALAB.ROOT.CA
make intermediate -e CA_INTERMEDIATE_DIR=/root/ca/brighton -e CN=SEALAB.BRIGHTON.CA
make chain -e CA_INTERMEDIATE_DIR=/root/ca/brighton
make server -e CA_INTERMEDIATE_DIR=/root/ca/brighton -e CN=clab-cademo-tor1
make client -e CA_INTERMEDIATE_DIR=/root/ca/brighton -e CN=admin

make intermediate -e CA_INTERMEDIATE_DIR=/root/ca/mtbaker -e CN=SEALAB.MTBAKER.CA
make chain -e CA_INTERMEDIATE_DIR=/root/ca/mtbaker
make server -e CA_INTERMEDIATE_DIR=/root/ca/mtbaker -e CN=clab-cademo-tor2
make client -e CA_INTERMEDIATE_DIR=/root/ca/mtbaker -e CN=admin


# TEST tor1
# gnmi -addr clab-cademo-tor1 -tls \
#     -cafile ca/brighton/certs/ca-chain.cert.pem \
#     -certfile ca/brighton/certs/admin.cert.pem \
#     -keyfile ca/brighton/private/admin.key.pem \
#     capabilities

# TEST tor2
# gnmi -addr clab-cademo-tor2 -tls \
#     -cafile ca/mtbaker/certs/ca-chain.cert.pem \
#     -certfile ca/mtbaker/certs/admin.cert.pem \
#     -keyfile ca/mtbaker/private/admin.key.pem \
#     capabilities