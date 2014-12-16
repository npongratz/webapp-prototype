# Ansible Role: run fileserver-linux on startup

This role ensures fileserver-linux is running upon startup (in theory). TODO: see if this is true.

Based on geerlingguy.packer-rhel

## Requirements

Prior to running this role via Packer, you need to make sure Ansible is installed via a shell provisioner, and that preliminary VM configuration (like adding a vagrant user to the appropriate group and the sudoers file) is complete, generally by using a Kickstart installation file (e.g. `ks.cfg`) with Packer. An example array of provisioners for your Packer .json template would be something like:

    "provisioners": [
      {
        "type": "shell",
        "execute_command": "echo 'vagrant' | {{.Vars}} sudo -S -E bash '{{.Path}}'",
        "script": "scripts/ansible.sh"
      },
      {
        "type": "ansible-local",
        "playbook_file": "ansible/main.yml",
        "role_paths": [
          "ansible/roles/npongratz.fileserver-linux",
        ]
      }
    ],

The files should contain, at a minimum:

**scripts/ansible.sh**:

    #!/bin/bash -eux
    # Install EPEL repository.
    yum -y install epel-release
    # Install Ansible.
    yum -y install ansible python-setuptools

**ansible/main.yml**:

    ---
    - hosts: all
      sudo: yes
      gather_facts: yes
      roles:
        - npongratz.fileserver-linux

You might also want to add another shell provisioner to run cleanup, erasing free space using `dd`, but this is not required (it will just save a little disk space in the Packer-produced .box file).

If you'd like to add additional roles, make sure you add them to the `role_paths` array in the template .json file, and then you can include them in `main.yml` as you normally would. The Ansible configuration will be run over a local connection from within the Linux environment, so all relevant files need to be copied over to the VM; configuratin for this is in the template .json file. Read more: [Ansible Local Provisioner](http://www.packer.io/docs/provisioners/ansible-local.html).

## Role Variables

None.

## Dependencies

None.

## Example Playbook

    - hosts: all
      roles:
        - { role: npongratz.fileserver-linux }

## License

MIT / BSD

## Author Information

This role was created in 2014 by [Nick Pongratz](https://github.com/npongratz), based on [Jeff Geerling](https://github.com/geerlingguy)'s [ansible-role-packer-rhel](https://github.com/geerlingguy/ansible-role-packer-rhel).
