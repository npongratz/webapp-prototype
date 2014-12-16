TODO
=====

* Move binary from /tmp/fileserver-linux to /opt/bin/fileserver-linux

* Run binary with CWD=/srv/share/

* Run binary as user vagrant

* Figure out better name than "Go webapp VM prototype"

* Determine whether npongratz.fileserver-linux is necessary and/or helpful
  * Think I can remove it: it did not ensure the service was running

* Parameterize "fileserver-linux" and other stuff

* Figure out if curl test failure in README.md reports to STDERR or STDOUT

* ? Move systemd unit to /usr/lib/systemd/user/ ?

* Figure out why Vagrant cached .box is not being overwritten as expected

* Remove build cruft in /tmp

* Possibly remove some/all of the `bash -x` chattiness
