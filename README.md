# CA Root Demo

### reset...

```bash
rm -rf ca
```

## CA Root

- CN: SEALAB.ROOT.CA

```bash
make root -e CN=SEALAB.ROOT.CA
mkdir -p ca/certs ca/crl ca/private ca/csr ca/newcerts
cp openssl.ca.cnf ca/openssl.cnf
cat /dev/null > ca/index.txt
echo 1000 > ca/serial
openssl genrsa -out ca/private/ca.key.pem 4096
```

```
Generating RSA private key, 4096 bit long modulus (2 primes)
..................................................................++++
............................................................................................................................................................................................++++
e is 65537 (0x010001)
openssl req -batch -config ca/openssl.cnf \
        -key ca/private/ca.key.pem \
        -out ca/certs/ca.cert.pem \
        -subj '/CN=SEALAB.ROOT.CA/ST=Washington/L=Seattle/O=Lab/OU=Seattle Lab Certificate Authority/C=US' \
        -new -x509 -days 7300 -sha256 -extensions v3_ca
bash-5.1$ 
```

## Intermediate - SEALAB.BRIGHTON.CA

- CN: SEALAB.BRIGHTON.CA
- CA_INTERMEDIATE_DIR: ca/brighton

```bash
make intermediate -e CA_INTERMEDIATE_DIR=ca/brighton -e CN=SEALAB.BRIGHTON.CA
mkdir -p ca/brighton/certs ca/brighton/crl ca/brighton/private ca/brighton/csr ca/brighton/newcerts
jinja2 -D dir=ca/brighton -o ca/brighton/openssl.cnf openssl.intermediate.cnf
cat /dev/null > ca/brighton/index.txt
echo 1000 > ca/brighton/serial
echo 1000 > ca/brighton/crlnumber
openssl genrsa -out ca/brighton/private/intermediate.key.pem 4096
```

Output:

```
Generating RSA private key, 4096 bit long modulus (2 primes)
.................++++
.....................++++
e is 65537 (0x010001)
openssl req -batch -config ca/brighton/openssl.cnf -new -sha256 \
        -key ca/brighton/private/intermediate.key.pem \
        -out ca/brighton/csr/intermediate.csr.pem \
        -subj '/CN=SEALAB.BRIGHTON.CA/ST=Washington/L=Seattle/O=Lab/OU=Seattle Lab Certificate Authority/C=US'
openssl ca -batch -config ca/openssl.cnf \
        -extensions v3_intermediate_ca \
        -days 3650 -notext -md sha256 \
        -in ca/brighton/csr/intermediate.csr.pem \
        -out ca/brighton/certs/intermediate.cert.pem
Using configuration from ca/openssl.cnf
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 4096 (0x1000)
        Validity
            Not Before: Mar 14 17:41:02 2023 GMT
            Not After : Mar 11 17:41:02 2033 GMT
        Subject:
            countryName               = US
            stateOrProvinceName       = Washington
            organizationName          = Lab
            organizationalUnitName    = Seattle Lab Certificate Authority
            commonName                = SEALAB.BRIGHTON.CA
        X509v3 extensions:
            X509v3 Subject Key Identifier: 
                A2:60:A1:95:B7:D8:48:0B:B7:B7:9A:58:C1:A4:BB:A9:81:FD:94:ED
            X509v3 Authority Key Identifier: 
                keyid:8A:67:92:85:12:B0:E4:69:4A:14:5F:E0:C5:A6:E3:1D:8E:2F:4A:18

            X509v3 Basic Constraints: critical
                CA:TRUE, pathlen:0
            X509v3 Key Usage: critical
                Digital Signature, Certificate Sign, CRL Sign
Certificate is to be certified until Mar 11 17:41:02 2033 GMT (3650 days)

Write out database with 1 new entries
Data Base Updated

```

### Generate chain

```bash
make chain -e CA_INTERMEDIATE_DIR=ca/brighton
cat ca/brighton/certs/intermediate.cert.pem \
      ca/certs/ca.cert.pem > ca/brighton/certs/ca-chain.cert.pem
```

## Generate and sign server cert

- CN: clab-ca-tor1
- CA_INTERMEDIATE_DIR: ca/brighton

```bash
make server -e CA_INTERMEDIATE_DIR=ca/brighton -e CN=clab-ca-tor1
jinja2 -D san=clab-ca-tor1 -D dir=ca/brighton \
    -o ca/brighton/openssl.clab-ca-tor1.cnf
    openssl.intermediate.cnf
openssl genrsa -out ca/brighton/private/clab-ca-tor1.key.pem 2048
```

```
Generating RSA private key, 2048 bit long modulus (2 primes)
......................+++++
.......................+++++
e is 65537 (0x010001)
chmod 444 ca/brighton/private/clab-ca-tor1.key.pem 
openssl req -config ca/brighton/openssl.clab-ca-tor1.cnf -new -sha256 \
        -key ca/brighton/private/clab-ca-tor1.key.pem \
        -out ca/brighton/csr/clab-ca-tor1.csr.pem \
        -subj '/CN=clab-ca-tor1/ST=Washington/L=Seattle/O=Lab/OU=Seattle Lab Certificate Authority/C=US'
openssl ca -batch -config ca/brighton/openssl.clab-ca-tor1.cnf \
        -in ca/brighton/csr/clab-ca-tor1.csr.pem \
        -out ca/brighton/certs/clab-ca-tor1.cert.pem \
        -extensions server_cert -days 375  -notext -md sha256
Using configuration from ca/brighton/openssl.clab-ca-tor1.cnf
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 4096 (0x1000)
        Validity
            Not Before: Mar 14 17:43:28 2023 GMT
            Not After : Mar 23 17:43:28 2024 GMT
        Subject:
            countryName               = US
            stateOrProvinceName       = Washington
            localityName              = Seattle
            organizationName          = Lab
            organizationalUnitName    = Seattle Lab Certificate Authority
            commonName                = clab-ca-tor1
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            Netscape Cert Type: 
                SSL Server
            Netscape Comment: 
                OpenSSL Generated Server Certificate
            X509v3 Subject Key Identifier: 
                C5:44:A0:52:40:DE:1F:FA:45:7F:4D:F9:EC:44:03:FA:E4:97:98:48
            X509v3 Authority Key Identifier: 
                keyid:A2:60:A1:95:B7:D8:48:0B:B7:B7:9A:58:C1:A4:BB:A9:81:FD:94:ED
                DirName:/CN=SEALAB.ROOT.CA/ST=Washington/L=Seattle/O=Lab/OU=Seattle Lab Certificate Authority/C=US
                serial:10:00

            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
            X509v3 Subject Alternative Name: 
                DNS:clab-ca-tor1
Certificate is to be certified until Mar 23 17:43:28 2024 GMT (375 days)

Write out database with 1 new entries
Data Base Updated
bash-5.1$ 
```

### Deploy server cert 

- SERVER: clab-ca-tor1

```bash
scp \
    ca/brighton/certs/ca-chain.cert.pem \
    ca/brighton/certs/clab-ca-tor1.cert.pem \
    ca/brighton/private/clab-ca-tor1.key.pem \
    admin@clab-ca-tor1:/var/tmp
```

```bash
$ ssh -l admin clab-ca-tor1
Warning: Permanently added 'clab-ca-tor1' (ED25519) to the list of known hosts.
tor1#copy flash:ca-chain.cert.pem certificate:
Copy completed successfully.
tor1#copy flash:clab-ca-tor1.cert.pem certificate:
Copy completed successfully.
tor1#copy flash:clab-ca-tor1.key.pem sslkey:
Copy completed successfully.
tor1#configure 
tor1(config)#management security 
tor1(config-mgmt-security)#ssl profile BRIGHTON
tor1(config-mgmt-sec-ssl-profile-BRIGHTON)#trust certificate ca-chain.cert.pem 
tor1(config-mgmt-sec-ssl-profile-BRIGHTON)#certificate clab-ca-tor1.cert.pem key clab-ca-tor1.key.pem 
tor1(config-mgmt-sec-ssl-profile-BRIGHTON)#exit
tor1(config-mgmt-security)#exit
tor1(config)#show management security ssl profile BRIGHTON 
   Profile        State    Additional Info                         
-------------- ----------- ----------------------------------------
   BRIGHTON       valid    Certificate 'clab-ca-tor1.cert.pem' 
                           hostname of this device does not match  
                           any entry of the Common Name nor Subject
                           Alternative Name in the certificate     

tor1(config)#hostname clab-ca-tor1
clab-ca-tor1(config)#show management security ssl profile BRIGHTON
   Profile        State    
-------------- ----------- 
   BRIGHTON       valid    

clab-ca-tor1(config)#

clab-ca-tor1(config)#management api gnmi 
clab-ca-tor1(config-mgmt-api-gnmi)#transport grpc default 
clab-ca-tor1(config-gnmi-transport-default)#ssl profile BRIGHTON 
clab-ca-tor1(config-gnmi-transport-default)#end

clab-ca-tor1#show management api gnmi
Transport: default
Enabled: yes
Server: running on port 6030, in MGMT VRF
SSL profile: BRIGHTON
QoS DSCP: none
Authorization required: no
Accounting requests: no
Certificate username authentication: no
Notification timestamp: last change time
Listen addresses: ::
```

### Generate client pair

```bash
bash-5.1$ make client -e CA_INTERMEDIATE_DIR=ca/brighton -e CN=admin
openssl genrsa -out ca/brighton/private/admin.key.pem 2048
Generating RSA private key, 2048 bit long modulus (2 primes)
..+++++
...........................................+++++
e is 65537 (0x010001)
chmod 444 ca/brighton/private/admin.key.pem
openssl req -new -sha256 -days 375  \
        -key ca/brighton/private/admin.key.pem \
        -out ca/brighton/csr/admin.csr.pem \
        -subj '/CN=admin'
Ignoring -days; not generating a certificate
openssl ca -batch -config ca/brighton/openssl.cnf \
        -extensions usr_cert -days 375  -md sha256 \
        -in ca/brighton/csr/admin.csr.pem \
        -out ca/brighton/certs/admin.cert.pem
Using configuration from ca/brighton/openssl.cnf
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 4097 (0x1001)
        Validity
            Not Before: Mar 14 18:15:51 2023 GMT
            Not After : Mar 23 18:15:51 2024 GMT
        Subject:
            commonName                = admin
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            Netscape Cert Type: 
                SSL Client, S/MIME
            Netscape Comment: 
                OpenSSL Generated Client Certificate
            X509v3 Subject Key Identifier: 
                30:84:8B:B3:6A:AD:E6:70:48:7C:7E:FE:3F:69:3B:68:58:15:AE:DB
            X509v3 Authority Key Identifier: 
                keyid:A2:60:A1:95:B7:D8:48:0B:B7:B7:9A:58:C1:A4:BB:A9:81:FD:94:ED

            X509v3 Key Usage: critical
                Digital Signature, Non Repudiation, Key Encipherment
            X509v3 Extended Key Usage: 
                TLS Web Client Authentication, E-mail Protection
Certificate is to be certified until Mar 23 18:15:51 2024 GMT (375 days)

Write out database with 1 new entries
Data Base Upda
```

### Test gNMI authentication

```bash
$ gnmi -addr clab-ca-tor1 -tls \
    -cafile ca/brighton/certs/ca-chain.cert.pem \
    -certfile ca/brighton/certs/admin.cert.pem \
    -keyfile ca/brighton/private/admin.key.pem \
    capabilities
Version: 0.7.0
SupportedModel: name:"openconfig-macsec" organization:"OpenConfig working group" version:"1.0.0"
SupportedModel: name:"openconfig-procmon" organization:"OpenConfig working group" version:"0.4.0"
SupportedModel: name:"openconfig-relay-agent" organization:"OpenConfig working group" version:"0.1.1"
SupportedModel: name:"openconfig-policy-forwarding" organization:"OpenConfig working group" version:"0.5.0"
SupportedModel: name:"openconfig-vlan" organization:"OpenConfig working group" version:"3.2.1"
SupportedModel: name:"openconfig-pf-srte" organization:"OpenConfig working group" version:"0.2.0"
SupportedModel: name:"openconfig-isis" organization:"OpenConfig working group" version:"1.0.0"
SupportedModel: name:"ietf-interfaces" organization:"IETF NETMOD (Network Modeling) Working Group"
SupportedModel: name:"arista-exp-eos-varp-intf" organization:"Arista Networks <http://arista.com/>"
...
```


### Now - generate a new intermediate

- CA_INTERMEDIATE_DIR: ca/mtbaker
- CN: SEALAB.MTBAKER.CA

```bash
bash-5.1$ make intermediate -e CA_INTERMEDIATE_DIR=ca/mtbaker -e CN=SEALAB.MTBAKER.CA
mkdir -p ca/mtbaker/certs ca/mtbaker/crl ca/mtbaker/private ca/mtbaker/csr ca/mtbaker/newcerts
jinja2 -D dir=ca/mtbaker -o ca/mtbaker/openssl.cnf openssl.intermediate.cnf
cat /dev/null > ca/mtbaker/index.txt
echo 1000 > ca/mtbaker/serial
echo 1000 > ca/mtbaker/crlnumber
openssl genrsa -out ca/mtbaker/private/intermediate.key.pem 4096
Generating RSA private key, 4096 bit long modulus (2 primes)
......................................++++
.......................................................................................................++++
e is 65537 (0x010001)
openssl req -batch -config ca/mtbaker/openssl.cnf -new -sha256 \
        -key ca/mtbaker/private/intermediate.key.pem \
        -out ca/mtbaker/csr/intermediate.csr.pem \
        -subj '/CN=SEALAB.MTBAKER.CA/ST=Washington/L=Seattle/O=Lab/OU=Seattle Lab Certificate Authority/C=US'
openssl ca -batch -config ca/openssl.cnf \
        -extensions v3_intermediate_ca \
        -days 3650 -notext -md sha256 \
        -in ca/mtbaker/csr/intermediate.csr.pem \
        -out ca/mtbaker/certs/intermediate.cert.pem
Using configuration from ca/openssl.cnf
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 4097 (0x1001)
        Validity
            Not Before: Mar 14 18:19:08 2023 GMT
            Not After : Mar 11 18:19:08 2033 GMT
        Subject:
            countryName               = US
            stateOrProvinceName       = Washington
            organizationName          = Lab
            organizationalUnitName    = Seattle Lab Certificate Authority
            commonName                = SEALAB.MTBAKER.CA
        X509v3 extensions:
            X509v3 Subject Key Identifier: 
                05:DB:92:E3:36:65:FC:80:76:97:3F:C9:9D:10:DE:26:66:BB:29:F8
            X509v3 Authority Key Identifier: 
                keyid:8A:67:92:85:12:B0:E4:69:4A:14:5F:E0:C5:A6:E3:1D:8E:2F:4A:18

            X509v3 Basic Constraints: critical
                CA:TRUE, pathlen:0
            X509v3 Key Usage: critical
                Digital Signature, Certificate Sign, CRL Sign
Certificate is to be certified until Mar 11 18:19:08 2033 GMT (3650 days)

Write out database with 1 new entries
Data Base Updated
```

### Generate chain

- CA_INTERMEDIATE_DIR: ca/mtbaker

```bash
bash-5.1$ make chain -e CA_INTERMEDIATE_DIR=ca/mtbaker
cat ca/mtbaker/certs/intermediate.cert.pem \
      ca/certs/ca.cert.pem > ca/mtbaker/certs/ca-chain.cert.pem
```

### Generate tor2 cert

- CA_INTERMEDIATE_DIR: ca/mtbaker
- CN: clab-ca-tor2

```bash
bash-5.1$ make server -e CA_INTERMEDIATE_DIR=ca/mtbaker -e CN=clab-ca-tor2
jinja2 -D san=clab-ca-tor2 -D dir=ca/mtbaker -o ca/mtbaker/openssl.clab-ca-tor2.cnf openssl.intermediate.cnf
openssl genrsa -out ca/mtbaker/private/clab-ca-tor2.key.pem 2048
Generating RSA private key, 2048 bit long modulus (2 primes)
..............+++++
.........+++++
e is 65537 (0x010001)
chmod 444 ca/mtbaker/private/clab-ca-tor2.key.pem 
openssl req -config ca/mtbaker/openssl.clab-ca-tor2.cnf -new -sha256 \
        -key ca/mtbaker/private/clab-ca-tor2.key.pem \
        -out ca/mtbaker/csr/clab-ca-tor2.csr.pem \
        -subj '/CN=clab-ca-tor2/ST=Washington/L=Seattle/O=Lab/OU=Seattle Lab Certificate Authority/C=US'
openssl ca -batch -config ca/mtbaker/openssl.clab-ca-tor2.cnf \
        -in ca/mtbaker/csr/clab-ca-tor2.csr.pem \
        -out ca/mtbaker/certs/clab-ca-tor2.cert.pem \
        -extensions server_cert -days 375  -notext -md sha256
Using configuration from ca/mtbaker/openssl.clab-ca-tor2.cnf
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 4096 (0x1000)
        Validity
            Not Before: Mar 14 18:20:09 2023 GMT
            Not After : Mar 23 18:20:09 2024 GMT
        Subject:
            countryName               = US
            stateOrProvinceName       = Washington
            localityName              = Seattle
            organizationName          = Lab
            organizationalUnitName    = Seattle Lab Certificate Authority
            commonName                = clab-ca-tor2
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            Netscape Cert Type: 
                SSL Server
            Netscape Comment: 
                OpenSSL Generated Server Certificate
            X509v3 Subject Key Identifier: 
                A6:47:89:AE:33:09:D8:16:F3:89:31:48:1E:DA:82:71:BD:A5:6B:99
            X509v3 Authority Key Identifier: 
                keyid:05:DB:92:E3:36:65:FC:80:76:97:3F:C9:9D:10:DE:26:66:BB:29:F8
                DirName:/CN=SEALAB.ROOT.CA/ST=Washington/L=Seattle/O=Lab/OU=Seattle Lab Certificate Authority/C=US
                serial:10:01

            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
            X509v3 Subject Alternative Name: 
                DNS:clab-ca-tor2
Certificate is to be certified until Mar 23 18:20:09 2024 GMT (375 days)

Write out database with 1 new entries
Data Base Updated
bash-5.1$ 
```

### Deploy server cert 

- SERVER: clab-ca-tor2

```bash
scp \
    ca/mtbaker/certs/ca-chain.cert.pem \
    ca/mtbaker/certs/clab-ca-tor2.cert.pem \
    ca/mtbaker/private/clab-ca-tor2.key.pem \
    admin@clab-ca-tor2:/mnt/flash
```

### Configure server

```bash
clab-ca-tor2#copy flash:ca-chain.cert.pem certificate:
Copy completed successfully.
clab-ca-tor2#copy flash:clab-ca-tor2.cert.pem certificate:
Copy completed successfully.
clab-ca-tor2#copy flash:clab-ca-tor2.key.pem sslkey:
Copy completed successfully.
clab-ca-tor2#configure 
clab-ca-tor2(config)#management security
clab-ca-tor2(config-mgmt-security)#ssl profile MTBAKER
clab-ca-tor2(config-mgmt-sec-ssl-profile-MTBAKER)#certificate clab-ca-tor2.cert.pem key clab-ca-tor2.key.pem
clab-ca-tor2(config-mgmt-sec-ssl-profile-MTBAKER)#trust certificate ca-chain.cert.pem
clab-ca-tor2(config-mgmt-sec-ssl-profile-MTBAKER)#exit
clab-ca-tor2(config-mgmt-security)#exit
clab-ca-tor2(config)#management api gnmi 
clab-ca-tor2(config-mgmt-api-gnmi)#transport grpc default 
clab-ca-tor2(config-gnmi-transport-default)#ssl profile MTBAKER 
clab-ca-tor2(config-gnmi-transport-default)#end
clab-ca-tor2#show management api gnmi
Transport: default
Enabled: yes
Server: running on port 6030, in MGMT VRF
SSL profile: MTBAKER
QoS DSCP: none
Authorization required: no
Accounting requests: no
Certificate username authentication: no
Notification timestamp: last change time
Listen addresses: ::
```

### Test gNMI using a different intermediate - FAILS

```bash
$ gnmi -addr clab-ca-tor2 -tls -cafile ca/brighton/certs/ca-chain.cert.pem -certfile ca/brighton/certs/admin.cert.pem -keyfile ca/brighton/private/admin.key.pem capabilities
F0314 18:28:38.695930   19674 client.go:191] rpc error: code = Unavailable desc = connection error: desc = "transport: authentication handshake failed: x509: certificate signed by unknown authority"
```
