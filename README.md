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

Go

 * https://golang.org/dl/
 * Tested with go version go1.3.1 darwin/amd64

gonative

 * Required only if host is not Linux
 * Recommend [calmh's fork of gonative](https://github.com/calmh/gonative)
 * `go get github.com/calmh/gonative && gonative -version=1.3 -platforms="linux_amd64"`

VirtualBox

 * https://www.virtualbox.org/wiki/Downloads
 * Tested with VirtualBox v4.3.20 r96996

Packer

 * https://packer.io/downloads.html
 * Tested with Packer v0.7.2 on OS X

Ansible

 * http://docs.ansible.com/intro_installation.html
 * Tested with Ansible 1.7.2

Vagrant

 * https://www.vagrantup.com/downloads.html
 * Tested with Vagrant 1.6.5

Local resources for the guest VM:

 * 1 vCPU
 * 512MB vRAM
 * 20GB thin-provisioned vHDD


Synopsis
---------
After installing all prerequisites:
```bash
$ git clone https://github.com/npongratz/webapp-prototype.git
$ cd webapp-prototype

$ # *Build on Linux host*:
$ go build -o app/bin/fileserver-linux app/src/main.go
    
$ # *Build on OS X, Windows, or any other non-Linux host*:
$   # First install gonative:
$ go get github.com/calmh/gonative
$ gonative -version=1.3 -platforms="linux_amd64"
$   # Then you can target linux/amd64:
$ GOOS=linux GOARCH=amd64 go/bin/go build -o app/bin/fileserver-linux app/src/main.go
    
$ packer build Packerfile-centos70-x86_64.json
$ vagrant up
$ curl localhost:8080/hello.txt
```

### Artifacts:

  * Linux ELF binary: app/bin/fileserver-linux
  * Vagrant .box found in builds/ directory
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
cross-compilation system in go/ of this project's directory:

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
    $ packer build Packerfile-centos70-x86_64.json

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

When you're done with the VM, remove the VM and associated files. Remember to
remove Vagrant's cached .box.

    $ vagrant destroy
    $ rm -rf ~/.vagrant.d/boxes/builds-*-fileserver-centos70-x86_64.box


More information
==================

Packer
-------
Creates a machine image as a build artifact.

Packer downloads the CentOS ISO (CentOS-7.0-1406-x86_64-Minimal.iso) and:

  1. Boots it with VirtualBox
  2. Provisions with Kickstart
  3. Further provisions with file uploads, shell scrips, and Ansible
  4. Clears out disk image's empty space for better compacting
  5. Shuts down VM
  6. Saves as .box in builds/ directory


File uploads
-------------

The following files and dirs/ are uploaded to the guest VM:

  * share/

    * Directory of static files that will be shared by the HTTP service we're
      implementing

  * app/bin/fileserver-linux

    * The HTTP service we're implementing
    * Created with a `go build`, see **Build Go Binary** above for
      instructions

  * app/fileserver-linux.service

    * systemd unit that starts fileserver-linux upon bootup

These files are initially uploaded to the guest's tmp/ directory, to be moved
to their ultimate destinations later by scripts executed by Packer.


Scripts
--------

Packer executes the following scripts on the guest VM for provisioning:

  * scripts/ansible.sh

    * Installs ansible on guest

  * scripts/prep-fileserver-linux.sh

    * Creates directories as needed
    * Moves uploaded files to proper destinations
    * Sets executable bit of fileserver-linux
    * Enables fileserver-linux to run at boot

  * scripts/cleanup.sh

    * Zeros out free space on guest VM for more effective compacting of vHDD


Ansible
--------

Our Ansible playbook further provisions the VM by implementing the following
roles:

  * [geerlingguy.nfs](https://github.com/geerlingguy/ansible-role-nfs)

    * Sets up NFS on the VM, presumably for file sharing.

  * [geerlingguy.packer-rhel](https://github.com/geerlingguy/ansible-role-packer-rhel)

    * Installs some stuff
    * Uninstalls other stuff
    * Fixes some network issues
    * Cleans up the filesystem

  * npongratz.fileserver-linux

    * Ensures the fileserver-linux service runs on boot
    * In theory. Unknown at present whether this is actually working.


Vagrant
--------

Packer uses [Vagrant for post-processing](https://packer.io/docs/post-processors/vagrant.html)
to convert the Packer build to a Vagrant .box artifact.

You can then use Vagrant on your host for easy manipulation of the VM as you
bring it up: `vagrant up`, `vagrant halt`, `vagrant destroy`, etc.

You can also configure the VM before bringing it up. For instance, change the
forwarded port by editing `config.vm.network` in **Vagrantfile**.


Questions and answers
======================

### Q: Why must I manually remove Vagrant's cached .box? ###

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

### Q: How can I use this prototype to deploy my own Go source to a VM? ###

A: Download the ZIP of this repo (or click Download ZIP button above). Extract
to a local directory. Edit the source in app/src. Follow **Synopsis** for
further instructions to build binary and VM.


Acknowledgements
==================

[Jeff Geerling on Github](https://github.com/geerlingguy) for an example Packer
setup for a minimal CentOS 7 Vagrant box provisioned with Ansible:

  * https://github.com/geerlingguy/packer-centos-7
  * https://github.com/geerlingguy/ansible-role-packer-rhel
  * https://github.com/geerlingguy/ansible-role-nfs
 
[Calvin Cheng on ServerFault](http://serverfault.com/users/93530/calvin-cheng) 
for a systemd unit that starts the Go webapp on boot:

  * http://serverfault.com/a/479437

Most of **Vagrantfile** comes from `vagrant init`.
