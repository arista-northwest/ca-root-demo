# CA Root Demo

### reset...

```bash
rm -rf ca
```

## CA Root

- CN: SEALAB.ROOT.CA

```bash
bash-5.1$ make root -e CN=SEALAB.ROOT.CA
mkdir -p /root/ca/certs /root/ca/crl /root/ca/private /root/ca/csr /root/ca/newcerts
cp openssl.ca.cnf /root/ca/openssl.cnf
cat /dev/null > /root/ca/index.txt
echo 1000 > /root/ca/serial
openssl genrsa -out /root/ca/private/ca.key.pem 4096
Generating RSA private key, 4096 bit long modulus (2 primes)
..................................................................++++
............................................................................................................................................................................................++++
e is 65537 (0x010001)
openssl req -batch -config /root/ca/openssl.cnf \
        -key /root/ca/private/ca.key.pem \
        -out /root/ca/certs/ca.cert.pem \
        -subj '/CN=SEALAB.ROOT.CA/ST=Washington/L=Seattle/O=Lab/OU=Seattle Lab Certificate Authority/C=US' \
        -new -x509 -days 7300 -sha256 -extensions v3_ca
bash-5.1$ 
```

## Intermediate - SEALAB.BRIGHTON.CA

- CN: SEALAB.BRIGHTON.CA
- CA_INTERMEDIATE_DIR: /root/ca/brighton

```bash
bash-5.1$ make intermediate -e CA_INTERMEDIATE_DIR=/root/ca/brighton -e CN=SEALAB.BRIGHTON.CA
mkdir -p /root/ca/brighton/certs /root/ca/brighton/crl /root/ca/brighton/private /root/ca/brighton/csr /root/ca/brighton/newcerts
jinja2 -D dir=/root/ca/brighton -o /root/ca/brighton/openssl.cnf openssl.intermediate.cnf
cat /dev/null > /root/ca/brighton/index.txt
echo 1000 > /root/ca/brighton/serial
echo 1000 > /root/ca/brighton/crlnumber
openssl genrsa -out /root/ca/brighton/private/intermediate.key.pem 4096
Generating RSA private key, 4096 bit long modulus (2 primes)
.................++++
.....................++++
e is 65537 (0x010001)
openssl req -batch -config /root/ca/brighton/openssl.cnf -new -sha256 \
        -key /root/ca/brighton/private/intermediate.key.pem \
        -out /root/ca/brighton/csr/intermediate.csr.pem \
        -subj '/CN=SEALAB.BRIGHTON.CA/ST=Washington/L=Seattle/O=Lab/OU=Seattle Lab Certificate Authority/C=US'
openssl ca -batch -config /root/ca/openssl.cnf \
        -extensions v3_intermediate_ca \
        -days 3650 -notext -md sha256 \
        -in /root/ca/brighton/csr/intermediate.csr.pem \
        -out /root/ca/brighton/certs/intermediate.cert.pem
Using configuration from /root/ca/openssl.cnf
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
bash-5.1C make chain -e CA_INTERMEDIATE_DIR=/root/ca/brighton
cat /root/ca/brighton/certs/intermediate.cert.pem \
      /root/ca/certs/ca.cert.pem > /root/ca/brighton/certs/ca-chain.cert.pem
```

## Generate and sign server cert

- CN: clab-cademo-tor1
- CA_INTERMEDIATE_DIR: /root/ca/brighton

```bash
bash-5.1$ make server -e CA_INTERMEDIATE_DIR=/root/ca/brighton -e CN=clab-cademo-tor1
jinja2 -D san=clab-cademo-tor1 -D dir=/root/ca/brighton -o /root/ca/brighton/openssl.clab-cademo-tor1.cnf openssl.intermediate.cnf
openssl genrsa -out /root/ca/brighton/private/clab-cademo-tor1.key.pem 2048
Generating RSA private key, 2048 bit long modulus (2 primes)
......................+++++
.......................+++++
e is 65537 (0x010001)
chmod 444 /root/ca/brighton/private/clab-cademo-tor1.key.pem 
openssl req -config /root/ca/brighton/openssl.clab-cademo-tor1.cnf -new -sha256 \
        -key /root/ca/brighton/private/clab-cademo-tor1.key.pem \
        -out /root/ca/brighton/csr/clab-cademo-tor1.csr.pem \
        -subj '/CN=clab-cademo-tor1/ST=Washington/L=Seattle/O=Lab/OU=Seattle Lab Certificate Authority/C=US'
openssl ca -batch -config /root/ca/brighton/openssl.clab-cademo-tor1.cnf \
        -in /root/ca/brighton/csr/clab-cademo-tor1.csr.pem \
        -out /root/ca/brighton/certs/clab-cademo-tor1.cert.pem \
        -extensions server_cert -days 375  -notext -md sha256
Using configuration from /root/ca/brighton/openssl.clab-cademo-tor1.cnf
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
            commonName                = clab-cademo-tor1
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
                DNS:clab-cademo-tor1
Certificate is to be certified until Mar 23 17:43:28 2024 GMT (375 days)

Write out database with 1 new entries
Data Base Updated
bash-5.1$ 
```

### Deploy server cert 

- SERVER: clab-cademo-tor1

```bash
scp \
    ca/brighton/certs/ca-chain.cert.pem \
    ca/brighton/certs/clab-cademo-tor1.cert.pem \
    ca/brighton/private/clab-cademo-tor1.key.pem \
    admin@clab-cademo-tor1:/mnt/flash
```

```bash
$ ssh -l admin clab-cademo-tor1
Warning: Permanently added 'clab-cademo-tor1' (ED25519) to the list of known hosts.
tor1#copy flash:ca-chain.cert.pem certificate:
Copy completed successfully.
tor1#copy flash:clab-cademo-tor1.cert.pem certificate:
Copy completed successfully.
tor1#copy flash:clab-cademo-tor1.key.pem sslkey:
Copy completed successfully.
tor1#configure 
tor1(config)#management security 
tor1(config-mgmt-security)#ssl profile BRIGHTON
tor1(config-mgmt-sec-ssl-profile-BRIGHTON)#trust certificate ca-chain.cert.pem 
tor1(config-mgmt-sec-ssl-profile-BRIGHTON)#certificate clab-cademo-tor1.cert.pem key clab-cademo-tor1.key.pem 
tor1(config-mgmt-sec-ssl-profile-BRIGHTON)#exit
tor1(config-mgmt-security)#exit
tor1(config)#show management security ssl profile BRIGHTON 
   Profile        State    Additional Info                         
-------------- ----------- ----------------------------------------
   BRIGHTON       valid    Certificate 'clab-cademo-tor1.cert.pem' 
                           hostname of this device does not match  
                           any entry of the Common Name nor Subject
                           Alternative Name in the certificate     

tor1(config)#hostname clab-cademo-tor1
clab-cademo-tor1(config)#show management security ssl profile BRIGHTON
   Profile        State    
-------------- ----------- 
   BRIGHTON       valid    

clab-cademo-tor1(config)#

clab-cademo-tor1(config)#management api gnmi 
clab-cademo-tor1(config-mgmt-api-gnmi)#transport grpc default 
clab-cademo-tor1(config-gnmi-transport-default)#ssl profile BRIGHTON 
clab-cademo-tor1(config-gnmi-transport-default)#end

clab-cademo-tor1#show management api gnmi
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
bash-5.1$ make client -e CA_INTERMEDIATE_DIR=/root/ca/brighton -e CN=admin
openssl genrsa -out /root/ca/brighton/private/admin.key.pem 2048
Generating RSA private key, 2048 bit long modulus (2 primes)
..+++++
...........................................+++++
e is 65537 (0x010001)
chmod 444 /root/ca/brighton/private/admin.key.pem
openssl req -new -sha256 -days 375  \
        -key /root/ca/brighton/private/admin.key.pem \
        -out /root/ca/brighton/csr/admin.csr.pem \
        -subj '/CN=admin'
Ignoring -days; not generating a certificate
openssl ca -batch -config /root/ca/brighton/openssl.cnf \
        -extensions usr_cert -days 375  -md sha256 \
        -in /root/ca/brighton/csr/admin.csr.pem \
        -out /root/ca/brighton/certs/admin.cert.pem
Using configuration from /root/ca/brighton/openssl.cnf
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
$ gnmi -addr clab-cademo-tor1 -tls \
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

- CA_INTERMEDIATE_DIR: /root/ca/mtbaker
- CN: SEALAB.MTBAKER.CA

```bash
bash-5.1$ make intermediate -e CA_INTERMEDIATE_DIR=/root/ca/mtbaker -e CN=SEALAB.MTBAKER.CA
mkdir -p /root/ca/mtbaker/certs /root/ca/mtbaker/crl /root/ca/mtbaker/private /root/ca/mtbaker/csr /root/ca/mtbaker/newcerts
jinja2 -D dir=/root/ca/mtbaker -o /root/ca/mtbaker/openssl.cnf openssl.intermediate.cnf
cat /dev/null > /root/ca/mtbaker/index.txt
echo 1000 > /root/ca/mtbaker/serial
echo 1000 > /root/ca/mtbaker/crlnumber
openssl genrsa -out /root/ca/mtbaker/private/intermediate.key.pem 4096
Generating RSA private key, 4096 bit long modulus (2 primes)
......................................++++
.......................................................................................................++++
e is 65537 (0x010001)
openssl req -batch -config /root/ca/mtbaker/openssl.cnf -new -sha256 \
        -key /root/ca/mtbaker/private/intermediate.key.pem \
        -out /root/ca/mtbaker/csr/intermediate.csr.pem \
        -subj '/CN=SEALAB.MTBAKER.CA/ST=Washington/L=Seattle/O=Lab/OU=Seattle Lab Certificate Authority/C=US'
openssl ca -batch -config /root/ca/openssl.cnf \
        -extensions v3_intermediate_ca \
        -days 3650 -notext -md sha256 \
        -in /root/ca/mtbaker/csr/intermediate.csr.pem \
        -out /root/ca/mtbaker/certs/intermediate.cert.pem
Using configuration from /root/ca/openssl.cnf
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

- CA_INTERMEDIATE_DIR: /root/ca/mtbaker

```bash
bash-5.1$ make chain -e CA_INTERMEDIATE_DIR=/root/ca/mtbaker
cat /root/ca/mtbaker/certs/intermediate.cert.pem \
      /root/ca/certs/ca.cert.pem > /root/ca/mtbaker/certs/ca-chain.cert.pem
```

### Generate tor2 cert

- CA_INTERMEDIATE_DIR: /root/ca/mtbaker
- CN: clab-cademo-tor2

```bash
bash-5.1$ make server -e CA_INTERMEDIATE_DIR=/root/ca/mtbaker -e CN=clab-cademo-tor2
jinja2 -D san=clab-cademo-tor2 -D dir=/root/ca/mtbaker -o /root/ca/mtbaker/openssl.clab-cademo-tor2.cnf openssl.intermediate.cnf
openssl genrsa -out /root/ca/mtbaker/private/clab-cademo-tor2.key.pem 2048
Generating RSA private key, 2048 bit long modulus (2 primes)
..............+++++
.........+++++
e is 65537 (0x010001)
chmod 444 /root/ca/mtbaker/private/clab-cademo-tor2.key.pem 
openssl req -config /root/ca/mtbaker/openssl.clab-cademo-tor2.cnf -new -sha256 \
        -key /root/ca/mtbaker/private/clab-cademo-tor2.key.pem \
        -out /root/ca/mtbaker/csr/clab-cademo-tor2.csr.pem \
        -subj '/CN=clab-cademo-tor2/ST=Washington/L=Seattle/O=Lab/OU=Seattle Lab Certificate Authority/C=US'
openssl ca -batch -config /root/ca/mtbaker/openssl.clab-cademo-tor2.cnf \
        -in /root/ca/mtbaker/csr/clab-cademo-tor2.csr.pem \
        -out /root/ca/mtbaker/certs/clab-cademo-tor2.cert.pem \
        -extensions server_cert -days 375  -notext -md sha256
Using configuration from /root/ca/mtbaker/openssl.clab-cademo-tor2.cnf
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
            commonName                = clab-cademo-tor2
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
                DNS:clab-cademo-tor2
Certificate is to be certified until Mar 23 18:20:09 2024 GMT (375 days)

Write out database with 1 new entries
Data Base Updated
bash-5.1$ 
```

### Deploy server cert 

- SERVER: clab-cademo-tor2

```bash
scp \
    ca/mtbaker/certs/ca-chain.cert.pem \
    ca/mtbaker/certs/clab-cademo-tor2.cert.pem \
    ca/mtbaker/private/clab-cademo-tor2.key.pem \
    admin@clab-cademo-tor2:/mnt/flash
```

### Configure server

```bash
clab-cademo-tor2#copy flash:ca-chain.cert.pem certificate:
Copy completed successfully.
clab-cademo-tor2#copy flash:clab-cademo-tor2.cert.pem certificate:
Copy completed successfully.
clab-cademo-tor2#copy flash:clab-cademo-tor2.key.pem sslkey:
Copy completed successfully.
clab-cademo-tor2#configure 
clab-cademo-tor2(config)#management security
clab-cademo-tor2(config-mgmt-security)#ssl profile MTBAKER
clab-cademo-tor2(config-mgmt-sec-ssl-profile-MTBAKER)#certificate clab-cademo-tor2.cert.pem key clab-cademo-tor2.key.pem
clab-cademo-tor2(config-mgmt-sec-ssl-profile-MTBAKER)#trust certificate ca-chain.cert.pem
clab-cademo-tor2(config-mgmt-sec-ssl-profile-MTBAKER)#exit
clab-cademo-tor2(config-mgmt-security)#exit
clab-cademo-tor2(config)#management api gnmi 
clab-cademo-tor2(config-mgmt-api-gnmi)#transport grpc default 
clab-cademo-tor2(config-gnmi-transport-default)#ssl profile MTBAKER 
clab-cademo-tor2(config-gnmi-transport-default)#end
clab-cademo-tor2#show management api gnmi
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
$ gnmi -addr clab-cademo-tor2 -tls -cafile ca/brighton/certs/ca-chain.cert.pem -certfile ca/brighton/certs/admin.cert.pem -keyfile ca/brighton/private/admin.key.pem capabilities
F0314 18:28:38.695930   19674 client.go:191] rpc error: code = Unavailable desc = connection error: desc = "transport: authentication handshake failed: x509: certificate signed by unknown authority"
```