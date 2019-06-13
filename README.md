# CA Root Demo

### reset...

```
rm certs/* crl/* private/* csr/* newcerts/*
cat /dev/null > index.txt
echo 1000 > serial
rm serial.old
rm index.*.old
```

### Generate root pair
```
openssl genrsa -out private/ca.key.pem 4096

openssl req -config openssl.cnf \
    -key private/ca.key.pem \
    -out certs/ca.cert.pem \
    -subj '/CN=Lab Root CA' \
    -new -x509 -days 7300 -sha256 -extensions v3_ca
```

### verify
```   
openssl x509 -noout -text -in certs/ca.cert.pem
```

### generate and sign server cert
```
openssl genrsa -out private/veos4.lab.lan.key.pem 2048

openssl req -config openssl.cnf \
    -key private/veos4.lab.lan.key.pem \
    -out csr/veos4.lab.lan.csr.pem \
    -subj '/CN=veos4.lab.lan' \
    -new -sha256

openssl ca -config openssl.cnf \
    -in csr/veos4.lab.lan.csr.pem \
    -out certs/veos4.lab.lan.cert.pem \
    -extensions server_cert -days 375 -notext -md sha256
```

### verify
```
openssl x509 -noout -text -in certs/veos4.lab.lan.cert.pem
openssl verify -CAfile certs/ca.cert.pem \
    certs/veos4.lab.lan.cert.pem
```

### copy server cert to switch
```
scp certs/ca.cert.pem \
    certs/veos4.lab.lan.cert.pem \
    private/veos4.lab.lan.key.pem \
    admin@veos4.lab.lan:/home/admin
```

### on switch
```
copy file:/home/admin/ca.cert.pem certificate:
copy file:/home/admin/veos4.lab.lan.cert.pem certificate:
copy file:/home/admin/veos4.lab.lan.key.pem sslkey:

configure
management security
  ssl profile EAPI
      certificate veos4.lab.lan.cert.pem key veos4.lab.lan.key.pem
      trust certificate ca.cert.pem

show management security ssl profile

management api http-commands
   no protocol http
   protocol https ssl profile EAPI
   no shutdown
```

### from CA root...
```
curl -X POST -d "show hostname" -u admin: --cacert certs/ca.cert.pem https://veos4.lab.lan/command-api
{"jsonrpc": "2.0", "id": null, "result": [{"fqdn": "veos-04.lab.lan", "hostname": "veos-04"}]}
```


## Client certificate authenication

### issue new client cert

```
openssl genrsa -out private/ops@lab.lan.key.pem 2048

openssl req -new -sha256 -days 375 \
  -key private/ops@lab.lan.key.pem \
  -out csr/ops@lab.lan.csr.pem \
  -subj '/CN=ops'

openssl ca -config openssl.cnf \
  -extensions usr_cert -days 375 -notext -md sha256 \
  -in csr/ops@lab.lan.csr.pem \
  -out certs/ops@lab.lan.cert.pem
```

### generate crl

```
openssl ca -config openssl.cnf   -gencrl -out crl/ca.crl.pem
```

### deploy

```
scp crl/ca.crl.pem admin@veos4:/home/admin
```

### on switch

```
configure
username ops privilege 15 secret ops
management security
   ssl profile EAPI
      crl ca.crl.pem
```

### test

```
curl -X POST -d "show hostname" \
    --cacert certs/ca.cert.pem \
    --cert certs/ops@lab.lan.cert.pem \
    --key private/ops@lab.lan.key.pem \
    https://veos4.lab.lan/command-api
```
