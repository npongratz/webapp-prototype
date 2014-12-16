Go Webapp+VM prototype: HTTP Fileserver 
============================================

Simple webapp that is:

 * written in Go,
 * hosted on a VirtualBox VM running CentOS 7,
 * created with Packer,
 * provisioned with Ansible,
 * using a Vagrant post-processor

The resulting VirtualBox-compatible .box can then be uploaded to a
distribution site, and/or deployed on another server running VirtualBox.

The webapp simply serves static files that Packer copied into the VM from this
project's share/ directory.


Requirements
-------------

Resources for a VM using 1 vCPU, 512MB vRAM, 20GB thin-provisioned vHDD

Go

 * [https://golang.org/dl/]()
 * Tested with go version go1.3.1 darwin/amd64

gonative

 * Required if host is not Linux
 * Recommend [https://github.com/calmh/gonative]() fork
 * `go get github.com/calmh/gonative && gonative -version=1.3 -platforms="linux_amd64"`

VirtualBox

 * [https://www.virtualbox.org/wiki/Downloads]()
 * Tested with VirtualBox v4.3.20 r96996

Packer

 * [https://packer.io/downloads.html]()
 * Tested with Packer v0.7.2 on OS X

Ansible

 * [http://docs.ansible.com/intro_installation.html]()
 * Tested with Ansible 1.7.2

Vagrant

 * [https://www.vagrantup.com/downloads.html]()
 * Tested with Vagrant 1.6.5


Synopsis
---------

    $ # *Build on Linux*:
    $ go build -o app/bin/fileserver-linux app/src/main.go
    
    $ # *Build on OS X*:
    $   # First install gonative (see Build Go Binary below)
    $   # Then you can target linux/amd64:
    $ GOOS=linux GOARCH=amd64 go/bin/go build -o app/bin/fileserver-linux app/src/main.go
    
    $ packer build Packerfile-fileserver-centos70-x86_64.json
    $ vagrant up
    $ curl localhost:8080/hello.txt

### Artifacts:

  * Linux ELF binary: app/bin/fileserver-linux
  * VirtualBox .box found in builds/ directory, suitable for deployment on
    any VirtualBox system.
    * fileserver-linux automatically runs on startup
    * If needed: `ssh -p 2222 vagrant@localhost`
      * Credentials: vagrant / vagrant

### Notes:

  * After first run, you'll need to delete Vagrant's cached .box. See
    **Build VM** below


Build Go binary
----------------

Source code is found in app/src/main.go. We're using Go to set up a webserver
that simply serves files in the current working directory when service was
started.

This binary targets Linux (CentOS 7 64-bit). If building the binary on an OS X
host, we'll first install calmh's fork of gonative to set up the
cross-compilation system:

    $ go get github.com/calmh/gonative
    $ gonative -version=1.3 -platforms="linux_amd64"

Then we can force GOOS and GOARCH:

    $ GOOS=linux GOARCH=amd64 go/bin/go build -o app/bin/fileserver-linux app/src/main.go

If building on Linux, we can skip the gonative installation, and use `go`
directly:

    $ go build -o app/bin/fileserver-linux app/src/main.go 

Build VM
---------

    $ # Remove old Vagrant crap:
    $ rm -rf ~/.vagrant.d/boxes/builds-*-fileserver-centos70-x86_64.box

    $ # Use Packer-Ansible-Vagrant stack to build and package for VirtualBox:
    $ packer build Packerfile-fileserver-centos70-x86_64.json

### Notes:

  * You can download the .iso and place it in the iso/ directory, but this
    is not necessary


Add to VirtualBox and boot VM
------------------------------

Easy:

    $ vagrant up

Not quite as easy:

  1. Add to VirtualBox
  2. Edit VM's Network settings to forward host port 8080, to guest port 8080


Verify
-------

Effectively `cat`s the hello.txt copied from share/ into VM's /srv/share:

    $ curl localhost:8080/hello.txt

You can also use a browser. On OS X:

    $ open http://localhost:8080/hello.txt
    $ open http://localhost:8080/hello.html


Test
-----

    $ curl --silent localhost:8080/hello.txt | diff --brief share/hello.txt -

Upon **success**: returns 0.

Upon **failure**: returns 1 and STDOUT (or perhaps STDERR; presently unknown):

    Files share/hello.txt and - differ


Destroy
--------

When you're done with the VM, remove it from VirtualBox and associated files
from your system. Remember to remove Vagrant's cached .box.

    $ vagrant destroy
    $ rm -rf ~/.vagrant.d/boxes/builds-*-fileserver-centos70-x86_64.box


More information
==================

Packer
-------
Packer downloads the CentOS ISO (CentOS-7.0-1406-x86_64-Minimal.iso) and:

  1. Boots it with VirtualBox
  2. Provisions with Kickstart
  3. Further provisions with file uploads and Ansible
  4. Clears out disk image's empty space for better compacting
  5. Shuts down VM
  6. Saves as .box in builds/ directory


Ansible
--------

We are using the following roles:

  * geerlingguy.nfs
  * geerlingguy.packer-rhel
  * npongratz.fileserver-linux

geerlingguy.nfs sets up NFS on the VM, presumably for file sharing.

geerlingguy.packer-rhel installs some stuff, uninstalls other stuff, fixes
some network issues, and cleans up the filesystem.

npongratz.fileserver-linux ensures the fileserver-linux service runs on boot
  * In theory. Unkown at present whether this is actually working.

Vagrant
--------

Packer uses Vagrant for post-processing to create the VirtualBox .box
artifact.

You can then use Vagrant for easy manipulation of the VM as you bring it up:
`vagrant up`, `vagrant halt`, `vagrant destroy`, etc.

You can also configure the VM before bringing it up. For instance, change the
forwarded port by editing `config.vm.network` in **Vagrantfile**.


Questions and answers
======================

### Q: Why remove Vagrant's cached .box? ###

A: For some reason, .box files were not being overwritten by Packer/Vagrant as
expected. So just remove the .box, and save yourself many hours of
troubleshooting and confusion. There is probably a better way to do this, so
this is noted in the TODO.


### Q: How can I speed up the .iso download? ###

A: Open Packerfile-*.json, and update the URL found in builders > iso_urls
using one of the mirrors found here:
http://isoredirect.centos.org/centos/7/isos/x86_64/

An alternative option is to download the .iso yourself and place it in the 
iso/ directory.


Acknowledgements
==================

[geerlingguy on Github](https://github.com/geerlingguy) for an example Packer
setup for a minimal CentOS 7 Vagrant box provisioned with Ansible

  * [https://github.com/geerlingguy/packer-centos-7]()
  * [https://github.com/geerlingguy/ansible-role-packer-rhel]()
  * [https://github.com/geerlingguy/ansible-role-nfs]()
 
[Calvin Cheng on ServerFault](http://serverfault.com/users/93530/calvin-cheng) 
for a systemd unit that starts the Go webapp on boot:

  * [http://serverfault.com/a/479437]()

