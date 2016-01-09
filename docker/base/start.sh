#!/bin/bash

/etc/init.d/ssh start
/usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -D
service apache2 start
/bin/bash
