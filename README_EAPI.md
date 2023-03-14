
### copy server cert to switch
```
```

### on switch
```
copy file:/home/admin/ca.cert.pem certificate:
copy file:/home/admin/veos3.lab.lan.cert.pem certificate:
copy file:/home/admin/veos3.lab.lan.key.pem sslkey:

configure
management security
  ssl profile EAPI
      certificate veos3.lab.lan.cert.pem key veos3.lab.lan.key.pem
      trust certificate ca.cert.pem

show management security ssl profile

management api http-commands
   no protocol http
   protocol https ssl profile EAPI
   no shutdown
```

### from CA root...
```
curl -X POST -d "show hostname" -u admin: --cacert certs/ca.cert.pem https://veos3.lab.lan/command-api
```

__Outputs:__

```
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
scp crl/ca.crl.pem admin@veos3:/home/admin
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
    https://veos3.lab.lan/command-api
```