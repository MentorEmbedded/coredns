# Makefile for building CoreDNS
SHELL = /bin/bash
GITCOMMIT:=$(shell git describe --dirty --always)
BINARY:=coredns
SYSTEM:=
CHECKS:=check
BUILDOPTS:=-v
UNAME := $(shell uname -m)
GO_VERSION ?= 1.20.6
WD := $(shell pwd)
export TOOLPATH := $(WD)
export GOROOT := $(TOOLPATH)/bin/go
export PATH := $(TOOLPATH)/bin:$(GOROOT)/bin:$(PATH)
MAKEPWD:=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))
CGO_ENABLED?=0

ifeq ($(UNAME),x86_64)
	ARCH = amd64
else
        ifeq ($(UNAME),aarch64)
	        ARCH = arm64
        endif
endif

.PHONY: all
all: coredns

.PHONY: coredns
coredns: gover $(CHECKS)
	CGO_ENABLED=$(CGO_ENABLED) $(SYSTEM) go build $(BUILDOPTS) -ldflags="-s -w -X github.com/coredns/coredns/coremain.GitCommit=$(GITCOMMIT)" -o $(BINARY)

.PHONY: gover
gover:
	$(info Checking essential build aspects.)
	@if [ ! -d $(WD)/bin ] ; then \
		mkdir $(WD)/bin ; \
	fi
	$(info Checking go version for compatibility.)
	@if [ ! -d $(GOROOT) ] ; then \
		echo "No go found, fetching compatible version." ; curl -sL https://go.dev/dl/go$(GO_VERSION).linux-$(ARCH).tar.gz | tar -C $$PWD/bin -zxf - ; \
	else \
		case "$$(go version)" in \
			*$(GO_VERSION)* ) echo "Compatible go version found." ;; \
			* ) echo "Go appears to be " $$(go version) ; echo "Incompatible or non-functional go found, fetching compatible version." ; curl -sL https://go.dev/dl/go$(GO_VERSION).linux-$(ARCH).tar.gz | tar -C $$PWD/bin -zxf - ;; \
		esac \
	fi

.PHONY: check
check: gover core/plugin/zplugin.go core/dnsserver/zdirectives.go

core/plugin/zplugin.go core/dnsserver/zdirectives.go: gover plugin.cfg
	go generate coredns.go
	go get

.PHONY: gen
gen: gover
	go generate coredns.go
	go get

.PHONY: pb
pb:
	$(MAKE) -C pb

.PHONY: clean
clean:
	if [ -d $(GOROOT) ] ; then \
		go clean ; \
	fi
	rm -fr coredns bin
