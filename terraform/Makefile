TERRAFORM_VERSION=0.15.0
TERRAFORM_DOWNLOAD_BASE_URL=https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}
TERRAFORM_CHECKSUM=terraform_${TERRAFORM_VERSION}_SHA256SUMS
UNAME_S := $(shell uname -s | tr A-Z a-z)
TERRAFORM_BIN=terraform_${TERRAFORM_VERSION}_${UNAME_S}_amd64.zip
TERRAFORM_INSTALLED_VERSION := $(shell ./terraform --version | head -n1 | grep -o "${TERRAFORM_VERSION}")

default: prepare build 

destroy:
	./terraform destroy

clean: destroy
	rm -rf .terraform
	rm terraform.tfstate*

prepare:
ifneq (${TERRAFORM_INSTALLED_VERSION},${TERRAFORM_VERSION})
	curl -o ${TERRAFORM_BIN} -fSL "${TERRAFORM_DOWNLOAD_BASE_URL}/${TERRAFORM_BIN}"
	curl -o ${TERRAFORM_CHECKSUM} -fSL "${TERRAFORM_DOWNLOAD_BASE_URL}/${TERRAFORM_CHECKSUM}"
	sha256sum -c --ignore-missing ${TERRAFORM_CHECKSUM}
	unzip -o ${TERRAFORM_BIN} terraform
	rm -f ${TERRAFORM_BIN} ${TERRAFORM_CHECKSUM}
endif

build:
	./terraform init
	./terraform apply

all: prepare build

