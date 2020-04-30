
CAROOTDIR    ?= ca
ROOT_CN      ?= Lab Root CA
OPENSSL_CONF ?= openssl.cnf
DAYS         ?= 375 
SERVER       = 
CLIENTID     = 

check-server:
ifndef SERVER
	$(error SERVER is undefined)
endif

check_client:
ifndef CLIENTID
	$(error CLIENTID is undefined)
endif

check_user:
ifndef USER
	$(error CLIENTID is undefined)
endif
distclean:
	rm -Rf ca

root:
	mkdir -p $(CAROOTDIR)/{certs,crl,private,csr,newcerts}
	cat /dev/null > $(CAROOTDIR)/index.txt
	echo 1000 > $(CAROOTDIR)/serial
	echo 1000 > $(CAROOTDIR)/crlnumber




	openssl genrsa -out $(CAROOTDIR)/private/ca.key.pem 4096

	openssl req -batch -config $(OPENSSL_CONF) \
		-key $(CAROOTDIR)/private/ca.key.pem \
		-out $(CAROOTDIR)/certs/ca.cert.pem \
		-subj '/CN=$(ROOT_CN)' \
		-new -x509 -days 7300 -sha256 -extensions v3_ca

verify:
	openssl x509 -noout -text -in $(CAROOTDIR)/certs/ca.cert.pem

server: check-server
	openssl genrsa -out $(CAROOTDIR)/private/$(SERVER).key.pem 2048

	openssl req -batch -config $(OPENSSL_CONF) \
		-key $(CAROOTDIR)/private/$(SERVER).key.pem \
		-out $(CAROOTDIR)/csr/$(SERVER).csr.pem \
		-subj '/CN=$(SERVER)' \
		-new -sha256

	openssl ca -batch -config $(OPENSSL_CONF) \
		-in $(CAROOTDIR)/csr/$(SERVER).csr.pem \
		-out $(CAROOTDIR)/certs/$(SERVER).cert.pem \
		-extensions server_cert -days $(DAYS) -notext -md sha256

client: check_client
	openssl genrsa -out $(CAROOTDIR)/private/$(CLIENTID).key.pem 2048

	openssl req -new -sha256 -days $(DAYS) \
		-key $(CAROOTDIR)/private/$(CLIENTID).key.pem \
		-out $(CAROOTDIR)/csr/$(CLIENTID).csr.pem \
		-subj '/CN=$(CLIENTID)'

	openssl ca -batch -config $(OPENSSL_CONF) \
		-extensions usr_cert -days $(DAYS) -notext -md sha256 \
		-in $(CAROOTDIR)/csr/$(CLIENTID).csr.pem \
		-out $(CAROOTDIR)/certs/$(CLIENTID).cert.pem

crl:
	openssl ca -config $(OPENSSL_CONF) -gencrl -out $(CAROOTDIR)/crl/ca.crl.pem

# deploy:
# 	scp certs/ca.cert.pem \
# 		certs/veos3.lab.lan.cert.pem \
# 		private/veos3.lab.lan.key.pem \
# 		admin@veos3.lab.lan:/home/admin