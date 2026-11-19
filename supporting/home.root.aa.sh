/home/root/aa.sh flags=(enforce) {
  /home/root/aa.sh r,
  /bin/sh ix,
  /bin/busybox ix,
  /bin/echo ix,
  /bin/head ix,
  /usr/bin/head ix,

  /lib/** mr,
  /lib64/** mr,
  /usr/lib/** mr,

  /home/root/aa.log rw,

  deny /etc/shadow r,
}

