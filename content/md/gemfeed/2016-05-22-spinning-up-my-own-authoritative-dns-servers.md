# Spinning up my own authoritative DNS servers

> Written by Paul Buetow 2016-05-22

## Background

Finally, I had time to deploy my own authoritative DNS servers (master and slave) for my domains "buetow.org" and "buetow.zone". My domain name provider is Schlund Technologies. They allow their customers to manually edit the DNS records (BIND files). And they also give you the opportunity to set your own authoritative DNS servers for your domains. From now, I am making use of that option.

[Schlund Technologies](http://www.schlundtech.de)  

## All FreeBSD Jails

In order to set up my authoritative DNS servers I installed a FreeBSD Jail dedicated for DNS with Puppet on my root machine as follows:

```
include freebsd

freebsd::ipalias { '2a01:4f8:120:30e8::14':
  ensure    => up,
  proto     => 'inet6',
  preflen   => '64',
  interface => 're0',
  aliasnum  => '5',
}

include jail::freebsd

class { 'jail':
  ensure              => present,
  jails_config        => {
    dns                     => {
      '_ensure'             => present,
      '_type'               => 'freebsd',
      '_mirror'             => 'ftp://ftp.de.freebsd.org',
      '_remote_path'        => 'FreeBSD/releases/amd64/10.1-RELEASE',
      '_dists'              => [ 'base.txz', 'doc.txz', ],
      '_ensure_directories' => [ '/opt', '/opt/enc' ],
      'host.hostname'       => "'dns.ian.buetow.org'",
      'ip4.addr'            => '192.168.0.15',
      'ip6.addr'            => '2a01:4f8:120:30e8::15',
    },
    .
    .
  }
}
```

## PF firewall

Please note that "dns.ian.buetow.org" is just the Jail name of the master DNS server (and "caprica.ian.buetow.org" the name of the Jail for the slave DNS server) and that I am using the DNS names "dns1.buetow.org" (master) and "dns2.buetow.org" (slave) for the actual service names (these are the DNS servers visible to the public). Please also note that the IPv4 address is an internal one. I have a PF to use NAT and PAT. The DNS ports are being forwarded (TCP and UDP) to that Jail. By default, all ports are blocked, so I am adding an exception rule for the IPv6 address as well. These are the PF rules in use:

```
% cat /etc/pf.conf
.
.
# dns.ian.buetow.org 
rdr pass on re0 proto tcp from any to $pub_ip port {53} -> 192.168.0.15
rdr pass on re0 proto udp from any to $pub_ip port {53} -> 192.168.0.15
pass in on re0 inet6 proto tcp from any to 2a01:4f8:120:30e8::15 port {53} flags S/SA keep state
pass in on re0 inet6 proto udp from any to 2a01:4f8:120:30e8::15 port {53} flags S/SA keep state
.
.
```

## Puppet managed BIND zone files

In "manifests/dns.pp" (the Puppet manifest for the Master DNS Jail itself) I configured the BIND DNS server this way:

```
class { 'bind_freebsd':
  config         => "puppet:///files/bind/named.${::hostname}.conf",
  dynamic_config => "puppet:///files/bind/dynamic.${::hostname}",
}
```

The Puppet module is actually a pretty simple one. It installs the file "/usr/local/etc/named/named.conf" and it populates the "/usr/local/etc/named/dynamicdb" directory with all my zone files.

Once (Puppet-) applied inside of the Jail I get this:

```
paul uranus:~/git/blog/source [4268]% ssh admin@dns1.buetow.org.buetow.org pgrep -lf named
60748 /usr/local/sbin/named -u bind -c /usr/local/etc/namedb/named.conf
paul uranus:~/git/blog/source [4269]% ssh admin@dns1.buetow.org.buetow.org tail -n 13 /usr/local/etc/namedb/named.conf
zone "buetow.org" {
    type master;
    notify yes;
    allow-update { key "buetoworgkey"; };
    file "/usr/local/etc/namedb/dynamic/buetow.org";
};

zone "buetow.zone" {
    type master;
    notify yes;
    allow-update { key "buetoworgkey"; };
    file "/usr/local/etc/namedb/dynamic/buetow.zone";
};
paul uranus:~/git/blog/source [4277]% ssh admin@dns1.buetow.org.buetow.org cat /usr/local/etc/namedb/dynamic/buetow.org
$TTL 3600
@    IN   SOA   dns1.buetow.org. domains.buetow.org. (
     25       ; Serial
     604800   ; Refresh
     86400    ; Retry
     2419200  ; Expire
     604800 ) ; Negative Cache TTL
; Infrastructure domains
@ IN NS dns1
@ IN NS dns2
* 300 IN CNAME web.ian
buetow.org. 86400 IN A 78.46.80.70
buetow.org. 86400 IN AAAA 2a01:4f8:120:30e8:0:0:0:11
buetow.org. 86400 IN MX 10 mail.ian
dns1 86400 IN A 78.46.80.70
dns1 86400 IN AAAA 2a01:4f8:120:30e8:0:0:0:15
dns2 86400 IN A 164.177.171.32
dns2 86400 IN AAAA 2a03:2500:1:6:20::
.
.
.
.
```

That is my master DNS server. My slave DNS server runs in another Jail on another bare metal machine. Everything is set up similar to the master DNS server. However, that server is located in a different DC and in different IP subnets. The only difference is the "named.conf". It's configured to be a slave and that means that the "dynamicdb" gets populated by BIND itself while doing zone transfers from the master.

```
paul uranus:~/git/blog/source [4279]% ssh admin@dns2.buetow.org tail -n 11 /usr/local/etc/namedb/named.conf
zone "buetow.org" {
    type slave;
    masters { 78.46.80.70; };
    file "/usr/local/etc/namedb/dynamic/buetow.org";
};

zone "buetow.zone" {
    type slave;
    masters { 78.46.80.70; };
    file "/usr/local/etc/namedb/dynamic/buetow.zone";
};
```

## The end result

The end result looks like this now:

```
% dig -t ns buetow.org
; <<>> DiG 9.10.3-P4-RedHat-9.10.3-12.P4.fc23 <<>> -t ns buetow.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 37883
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;buetow.org.			IN	NS

;; ANSWER SECTION:
buetow.org.		600	IN	NS	dns2.buetow.org.
buetow.org.		600	IN	NS	dns1.buetow.org.

;; Query time: 41 msec
;; SERVER: 192.168.1.254#53(192.168.1.254)
;; WHEN: Sun May 22 11:34:11 BST 2016
;; MSG SIZE  rcvd: 77

% dig -t any buetow.org @dns1.buetow.org
; <<>> DiG 9.10.3-P4-RedHat-9.10.3-12.P4.fc23 <<>> -t any buetow.org @dns1.buetow.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 49876
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 6, AUTHORITY: 0, ADDITIONAL: 7

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;buetow.org.			IN	ANY

;; ANSWER SECTION:
buetow.org.		86400	IN	A	78.46.80.70
buetow.org.		86400	IN	AAAA	2a01:4f8:120:30e8::11
buetow.org.		86400	IN	MX	10 mail.ian.buetow.org.
buetow.org.		3600	IN	SOA	dns1.buetow.org. domains.buetow.org. 25 604800 86400 2419200 604800
buetow.org.		3600	IN	NS	dns2.buetow.org.
buetow.org.		3600	IN	NS	dns1.buetow.org.

;; ADDITIONAL SECTION:
mail.ian.buetow.org.	86400	IN	A	78.46.80.70
dns1.buetow.org.	86400	IN	A	78.46.80.70
dns2.buetow.org.	86400	IN	A	164.177.171.32
mail.ian.buetow.org.	86400	IN	AAAA	2a01:4f8:120:30e8::12
dns1.buetow.org.	86400	IN	AAAA	2a01:4f8:120:30e8::15
dns2.buetow.org.	86400	IN	AAAA	2a03:2500:1:6:20::

;; Query time: 42 msec
;; SERVER: 78.46.80.70#53(78.46.80.70)
;; WHEN: Sun May 22 11:34:41 BST 2016
;; MSG SIZE  rcvd: 322
```

## Monitoring

For monitoring I am using Icinga2 (I am operating two Icinga2 instances in two different DCs). I may have to post another blog article about Icinga2 but to get the idea these were the snippets added to my Icinga2 configuration:

```
apply Service "dig" {
    import "generic-service"

    check_command = "dig"
    vars.dig_lookup = "buetow.org"
    vars.timeout = 30

    assign where host.name == "dns.ian.buetow.org" || host.name == "caprica.ian.buetow.org"
}

apply Service "dig6" {
    import "generic-service"

    check_command = "dig"
    vars.dig_lookup = "buetow.org"
    vars.timeout = 30
    vars.check_ipv6 = true

    assign where host.name == "dns.ian.buetow.org" || host.name == "caprica.ian.buetow.org"
}
```

## DNS update workflow

Whenever I have to change a DNS entry all have to do is:

* Git clone or update the Puppet repository
* Update/commit and push the zone file (e.g. "buetow.org")
* Wait for Puppet. Puppet will deploy that updated zone file. And it will reload the BIND server.
* The BIND server will notify all slave DNS servers (at the moment only one). And it will transfer the new version of the zone.

That's much more comfortable now than manually clicking at some web UIs at Schlund Technologies.

E-Mail me your thoughts at comments@mx.buetow.org!

[Go back to the main site](../)  