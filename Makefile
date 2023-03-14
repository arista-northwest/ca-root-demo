CA_ROOT_DIR    ?= /root/ca
CA_INTERMEDIATE_DIR ?= $(CA_ROOT_DIR)/intermediate
CN =
C ?= US
ST ?= Washington
L ?= Seattle
O ?= Lab

DAYS         ?= 375 

check-cn:

ifndef CN
	$(error CN is undefined)
endif

distclean:
	rm -Rf ca

clean:
	rm -Rf ca

root:
	mkdir -p $(CA_ROOT_DIR)/certs $(CA_ROOT_DIR)/crl $(CA_ROOT_DIR)/private $(CA_ROOT_DIR)/csr $(CA_ROOT_DIR)/newcerts
	
	cp openssl.ca.cnf $(CA_ROOT_DIR)/openssl.cnf
	
	cat /dev/null > $(CA_ROOT_DIR)/index.txt
	echo 1000 > $(CA_ROOT_DIR)/serial
#	echo 1000 > $(CA_ROOT_DIR)/crlnumber

	openssl genrsa -out $(CA_ROOT_DIR)/private/ca.key.pem 4096

	openssl req -batch -config $(CA_ROOT_DIR)/openssl.cnf \
		-key $(CA_ROOT_DIR)/private/ca.key.pem \
		-out $(CA_ROOT_DIR)/certs/ca.cert.pem \
		-subj '/CN=$(CN)/ST=$(ST)/L=$(L)/O=$(O)/OU=Seattle Lab Certificate Authority/C=$(C)' \
		-new -x509 -days 7300 -sha256 -extensions v3_ca

verify:
	openssl x509 -noout -text -in $(CA_ROOT_DIR)/certs/ca.cert.pem

intermediate:
	mkdir -p $(CA_INTERMEDIATE_DIR)/certs $(CA_INTERMEDIATE_DIR)/crl $(CA_INTERMEDIATE_DIR)/private $(CA_INTERMEDIATE_DIR)/csr $(CA_INTERMEDIATE_DIR)/newcerts
	jinja2 -D dir=$(CA_INTERMEDIATE_DIR) -o $(CA_INTERMEDIATE_DIR)/openssl.cnf openssl.intermediate.cnf
	cat /dev/null > $(CA_INTERMEDIATE_DIR)/index.txt
	echo 1000 > $(CA_INTERMEDIATE_DIR)/serial
	echo 1000 > $(CA_INTERMEDIATE_DIR)/crlnumber
	
	openssl genrsa -out $(CA_INTERMEDIATE_DIR)/private/intermediate.key.pem 4096

	openssl req -config $(CA_INTERMEDIATE_DIR)/openssl.cnf -new -sha256 \
		-key $(CA_INTERMEDIATE_DIR)/private/intermediate.key.pem \
		-out $(CA_INTERMEDIATE_DIR)/csr/intermediate.csr.pem \
		-subj '/CN=$(CN)/ST=$(ST)/L=$(L)/O=$(O)/OU=Seattle Lab Certificate Authority/C=$(C)'

	openssl ca -config $(CA_ROOT_DIR)/openssl.cnf \
		-extensions v3_intermediate_ca \
		-days 3650 -notext -md sha256 \
		-in $(CA_INTERMEDIATE_DIR)/csr/intermediate.csr.pem \
		-out $(CA_INTERMEDIATE_DIR)/certs/intermediate.cert.pem

chain:
	cat $(CA_INTERMEDIATE_DIR)/certs/intermediate.cert.pem \
      $(CA_ROOT_DIR)/certs/ca.cert.pem > $(CA_INTERMEDIATE_DIR)/certs/ca-chain.cert.pem

server: check-cn
	jinja2 -D san=$(CN) -D dir=$(CA_INTERMEDIATE_DIR) -o $(CA_INTERMEDIATE_DIR)/openssl.$(CN).cnf openssl.intermediate.cnf
	
	openssl genrsa -out $(CA_INTERMEDIATE_DIR)/private/$(CN).key.pem 2048

	chmod 444 $(CA_INTERMEDIATE_DIR)/private/$(CN).key.pem 

	openssl req -config $(CA_INTERMEDIATE_DIR)/openssl.$(CN).cnf -new -sha256 \
		-key $(CA_INTERMEDIATE_DIR)/private/$(CN).key.pem \
		-out $(CA_INTERMEDIATE_DIR)/csr/$(CN).csr.pem \
		-subj '/CN=$(CN)/ST=$(ST)/L=$(L)/O=$(O)/OU=Seattle Lab Certificate Authority/C=$(C)'

	openssl ca -batch -config $(CA_INTERMEDIATE_DIR)/openssl.$(CN).cnf \
		-in $(CA_INTERMEDIATE_DIR)/csr/$(CN).csr.pem \
		-out $(CA_INTERMEDIATE_DIR)/certs/$(CN).cert.pem \
		-extensions server_cert -days $(DAYS) -notext -md sha256

client: check-cn
	openssl genrsa -out $(CA_INTERMEDIATE_DIR)/private/$(CN).key.pem 2048
	chmod 444 $(CA_INTERMEDIATE_DIR)/private/$(CN).key.pem
	openssl req -new -sha256 -days $(DAYS) \
		-key $(CA_INTERMEDIATE_DIR)/private/$(CN).key.pem \
		-out $(CA_INTERMEDIATE_DIR)/csr/$(CN).csr.pem \
		-subj '/CN=$(CN)'

	openssl ca -batch -config $(CA_INTERMEDIATE_DIR)/openssl.cnf \
		-extensions usr_cert -days $(DAYS) -md sha256 \
		-in $(CA_INTERMEDIATE_DIR)/csr/$(CN).csr.pem \
		-out $(CA_INTERMEDIATE_DIR)/certs/$(CN).cert.pem

crl: prep _crl tidy
_crl:
	openssl ca -config $(OPENSSL_CONF) -gencrl -out $(CA_INTERMEDIATE_DIR)/crl/ca.crl.pem

# deploy:
# 	scp certs/ca.cert.pem \
# 		certs/veos3.lab.lan.cert.pem \
# 		private/veos3.lab.lan.key.pem \
# 		admin@veos3.lab.lan:/home/admin