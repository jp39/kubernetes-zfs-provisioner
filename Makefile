.PHONY: build install_zfs prepare install clean uninstall test integration_test
SHELL := /usr/bin/env bash

ZPOOL_SIZE=1 # in GB
zpool_dir := .zpool
zpool_disk := $(zpool_dir)/zpool.img
zpool_name_file := $(zpool_dir)/zpool.nfo
zpool_name := $(shell bash -c "cat .zpool/zpool.nfo || echo test$$RANDOM")
zfs_dataset := $(zpool_name)/zfs-provisioner

goreleaser_cmd ?= goreleaser release --snapshot --rm-dist --skip-sign

build:
	$(goreleaser_cmd)

install_zfs:
	sudo apt install -y zfsutils nfs-kernel-server

$(zpool_name_file):
	if [[ ! -d $(zpool_dir) ]]; then mkdir $(zpool_dir); fi
	# Create a disk image
	dd if=/dev/zero bs=1024M count=$(ZPOOL_SIZE) of=$$(pwd)/$(zpool_disk)
	echo $(zpool_name)
	sudo zpool create $(zpool_name) $$(pwd)/$(zpool_disk)
	echo "$(zpool_name)" > $(zpool_name_file)

/$(zfs_dataset): $(zpool_name_file)
	sudo zfs create $(zfs_dataset)
	sudo zfs allow -e create,destroy,snapshot,refreservation,refquota,share,sharenfs $(zfs_dataset)

prepare: /$(zfs_dataset)

install: build
	sudo dpkg -i dist/kubernetes-zfs-provisioner_linux_amd64.deb

clean:
	sudo zpool destroy $(zpool_name)
	rm -r -v $(zpool_dir)

uninstall:
	sudo apt remove -y -m kubernetes-zfs-provisioner
