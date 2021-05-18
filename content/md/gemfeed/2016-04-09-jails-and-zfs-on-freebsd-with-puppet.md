# Jails and ZFS with Puppet on FreeBSD

```
            __     __
           (( \---/ ))
            )__   __(
           / ()___() \
           \  /(_)\  /
            \ \_|_/ /
      _______>     <_______
     //\      |>o<|      /\\
     \\/___           ___\//
           |         |
           |         |
           |         |
           |         |
           `--....---'
             \     \
              \     `.     hjw
               \      `.
```

> Written by Paul Buetow 2016-04-09

Over the last couple of years I wrote quite a few Puppet modules in order to manage my personal server infrastructure. One of them manages FreeBSD Jails and another one ZFS file systems. I thought I would give a brief overview in how it looks and feels.

[https://github.com/snonux/puppet-modules](https://github.com/snonux/puppet-modules)  

## ZFS

The ZFS module is a pretty basic one. It does not manage ZFS pools yet as I am not creating them often enough which would justify implementing an automation. But let's see how we can create a ZFS file system (on an already given ZFS pool named ztank):

Puppet snippet:

```
zfs::create { 'ztank/foo':
  ensure     => present,
  filesystem => '/srv/foo',

  require => File['/srv'],
}
```

Puppet run:

```
admin alphacentauri:/opt/git/server/puppet/manifests [1212]% puppet.apply
Password:
Info: Loading facts
Info: Loading facts
Info: Loading facts
Info: Loading facts
Notice: Compiled catalog for alphacentauri.home in environment production in 7.14 seconds
Info: Applying configuration version '1460189837'
Info: mount[files]: allowing * access
Info: mount[restricted]: allowing * access
Notice: /Stage[main]/Main/Node[alphacentauri]/Zfs::Create[ztank/foo]/Exec[ztank/foo_create]/returns: executed successfully
Notice: Finished catalog run in 25.41 seconds
admin alphacentauri:~ [1213]% zfs list | grep foo
ztank/foo                     96K  1.13T    96K  /srv/foo
admin alphacentauri:~ [1214]% df | grep foo
ztank/foo                  1214493520        96 1214493424     0%    /srv/foo
admin alphacentauri:~ [1215]% 
```

The destruction of the file system just requires to set "ensure" to "absent" in Puppet:

```
zfs::create { 'ztank/foo':
  ensure     => absent,
  filesystem => '/srv/foo',

  require => File['/srv'],
}¬
```

Puppet run:

```
admin alphacentauri:/opt/git/server/puppet/manifests [1220]% puppet.apply
Password:
Info: Loading facts
Info: Loading facts
Info: Loading facts
Info: Loading facts
Notice: Compiled catalog for alphacentauri.home in environment production in 6.14 seconds
Info: Applying configuration version '1460190203'
Info: mount[files]: allowing * access
Info: mount[restricted]: allowing * access
Notice: /Stage[main]/Main/Node[alphacentauri]/Zfs::Create[ztank/foo]/Exec[zfs destroy -r ztank/foo]/returns: executed successfully
Notice: Finished catalog run in 22.72 seconds
admin alphacentauri:/opt/git/server/puppet/manifests [1221]% zfs list | grep foo
zsh: done       zfs list | 
zsh: exit 1     grep foo
admin alphacentauri:/opt/git/server/puppet/manifests [1222:1]% df | grep foo
zsh: done       df | 
zsh: exit 1     grep foo
```

## Jails

Here is an example in how a FreeBSD Jail can be created. The Jail will have its own public IPv6 address. And it will have its own internal IPv4 address with IPv4 NAT to the internet (this is due to the limitation that the host server only got one public IPv4 address which requires sharing between all the Jails).

Furthermore, Puppet will ensure that the Jail will have its own ZFS file system (internally it is using the ZFS module). Please notice that the NAT requires the packet filter to be setup correctly (not covered in this blog post).

```
include jail::freebsd

# Cloned interface for Jail IPv4 NAT
freebsd::rc_config { 'cloned_interfaces':
  value => 'lo1',
}
freebsd::rc_config { 'ipv4_addrs_lo1':
  value => '192.168.0.1-24/24'
}

freebsd::ipalias { '2a01:4f8:120:30e8::17':
  ensure    => up,
  proto     => 'inet6',
  preflen   => '64',
  interface => 're0',
  aliasnum  => '8',
}

class { 'jail':
  ensure              => present,
  jails_config        => {
    sync                     => {
      '_ensure'             => present,
      '_type'               => 'freebsd',
      '_mirror'             => 'ftp://ftp.de.freebsd.org',
      '_remote_path'        => 'FreeBSD/releases/amd64/10.1-RELEASE',
      '_dists'              => [ 'base.txz', 'doc.txz', ],
      '_ensure_directories' => [ '/opt', '/opt/enc' ],
      '_ensure_zfs'         => [ '/sync' ],
      'host.hostname'       => "'sync.ian.buetow.org'",
      'ip4.addr'            => '192.168.0.17',
      'ip6.addr'            => '2a01:4f8:120:30e8::17',
    },
  }
}
```

This is how the result looks like:

```
admin sun:/etc [1939]% puppet.apply
Info: Loading facts
Info: Loading facts
Info: Loading facts
Info: Loading facts
Notice: Compiled catalog for sun.ian.buetow.org in environment production in 1.80 seconds
Info: Applying configuration version '1460190986'
Notice: /Stage[main]/Jail/File[/etc/jail.conf]/ensure: created
Info: mount[files]: allowing * access
Info: mount[restricted]: allowing * access
Info: Computing checksum on file /etc/motd
Info: /Stage[main]/Motd/File[/etc/motd]: Filebucketed /etc/motd to puppet with sum fced1b6e89f50ef2c40b0d7fba9defe8
Notice: /Stage[main]/Jail/Jail::Create[sync]/File[/jail/sync]/ensure: created
Notice: /Stage[main]/Jail/Jail::Create[sync]/Zfs::Create[zroot/jail/sync]/Exec[zroot/jail/sync_create]/returns: executed successfully
Notice: /Stage[main]/Jail/Jail::Create[sync]/File[/jail/sync/opt]/ensure: created
Notice: /Stage[main]/Jail/Jail::Create[sync]/File[/jail/sync/opt/enc]/ensure: created
Notice: /Stage[main]/Jail/Jail::Create[sync]/Jail::Ensure_zfs[/sync]/Zfs::Create[zroot/jail/sync/sync]/Exec[zroot/jail/sync/sync_create]/returns: executed successfully
Notice: /Stage[main]/Jail/Jail::Create[sync]/Jail::Freebsd::Create[sync]/File[/jail/sync/.jailbootstrap]/ensure: created
Notice: /Stage[main]/Jail/Jail::Create[sync]/Jail::Freebsd::Create[sync]/File[/etc/fstab.jail.sync]/ensure: created
Notice: /Stage[main]/Jail/Jail::Create[sync]/Jail::Freebsd::Create[sync]/File[/jail/sync/.jailbootstrap/bootstrap.sh]/ensure: created
Notice: /Stage[main]/Jail/Jail::Create[sync]/Jail::Freebsd::Create[sync]/Exec[sync_bootstrap]/returns: executed successfully
Notice: Finished catalog run in 49.72 seconds
admin sun:/etc [1942]% ls -l /jail/sync
total 154
-r--r--r--   1 root  wheel  6198 11 Nov  2014 COPYRIGHT
drwxr-xr-x   2 root  wheel    47 11 Nov  2014 bin
drwxr-xr-x   7 root  wheel    43 11 Nov  2014 boot
dr-xr-xr-x   2 root  wheel     2 11 Nov  2014 dev
drwxr-xr-x  23 root  wheel   101  9 Apr 10:37 etc
drwxr-xr-x   3 root  wheel    50 11 Nov  2014 lib
drwxr-xr-x   3 root  wheel     4 11 Nov  2014 libexec
drwxr-xr-x   2 root  wheel     2 11 Nov  2014 media
drwxr-xr-x   2 root  wheel     2 11 Nov  2014 mnt
drwxr-xr-x   3 root  wheel     3  9 Apr 10:36 opt
dr-xr-xr-x   2 root  wheel     2 11 Nov  2014 proc
drwxr-xr-x   2 root  wheel   143 11 Nov  2014 rescue
drwxr-xr-x   2 root  wheel     6 11 Nov  2014 root
drwxr-xr-x   2 root  wheel   132 11 Nov  2014 sbin
drwxr-xr-x   2 root  wheel     2  9 Apr 10:36 sync
lrwxr-xr-x   1 root  wheel    11 11 Nov  2014 sys -> usr/src/sys
drwxrwxrwt   2 root  wheel     2 11 Nov  2014 tmp
drwxr-xr-x  14 root  wheel    14 11 Nov  2014 usr
drwxr-xr-x  24 root  wheel    24 11 Nov  2014 var
admin sun:/etc [1943]% zfs list | grep sync;df | grep sync
zroot/jail/sync                 162M   343G   162M  /jail/sync
zroot/jail/sync/sync            144K   343G   144K  /jail/sync/sync
/opt/enc                                                 5061624     84248    4572448     2%    /jail/sync/opt/enc
zroot/jail/sync                                        360214972    166372  360048600     0%    /jail/sync
zroot/jail/sync/sync                                   360048744       144  360048600     0%    /jail/sync/sync
admin sun:/etc [1944]% cat /etc/fstab.jail.sync
# Generated by Puppet for a Jail.
# Can contain file systems to be mounted curing jail start.
admin sun:/etc [1945]% cat /etc/jail.conf
# Generated by Puppet

allow.chflags = true;
exec.start = '/bin/sh /etc/rc';
exec.stop = '/bin/sh /etc/rc.shutdown';
mount.devfs = true;
mount.fstab = "/etc/fstab.jail.$name";
path = "/jail/$name";

sync {
      host.hostname = 'sync.ian.buetow.org';
      ip4.addr = 192.168.0.17;
      ip6.addr = 2a01:4f8:120:30e8::17;
}
admin sun:/etc [1955]% sudo service jail start sync
Password:
Starting jails: sync.
admin sun:/etc [1956]% jls | grep sync
   103  192.168.0.17    sync.ian.buetow.org           /jail/sync
admin sun:/etc [1957]% sudo jexec 103 /bin/csh
root@sync:/ # ifconfig -a
re0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> metric 0 mtu 1500
     options=8209b<RXCSUM,TXCSUM,VLAN_MTU,VLAN_HWTAGGING,VLAN_HWCSUM,WOL_MAGIC,LINKSTATE>
     ether 50:46:5d:9f:fd:1e
     inet6 2a01:4f8:120:30e8::17 prefixlen 64 
     nd6 options=8021<PERFORMNUD,AUTO_LINKLOCAL,DEFAULTIF>
     media: Ethernet autoselect (1000baseT <full-duplex>)
     status: active
lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> metric 0 mtu 16384
     options=600003<RXCSUM,TXCSUM,RXCSUM_IPV6,TXCSUM_IPV6>
     nd6 options=21<PERFORMNUD,AUTO_LINKLOCAL>
     lo1: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> metric 0 mtu 16384
     options=600003<RXCSUM,TXCSUM,RXCSUM_IPV6,TXCSUM_IPV6>
     inet 192.168.0.17 netmask 0xffffffff 
     nd6 options=29<PERFORMNUD,IFDISABLED,AUTO_LINKLOCAL>
```

## Inside-Jail Puppet

To automatically setup the applications running in the Jail I am using Puppet as well. I wrote a few scripts which bootstrap Puppet inside of a newly created Jail. It is doing the following:

* Mounts an encrypted container (containing a secret Puppet manifests [git repository])
* Activates "pkg-ng", the FreeBSD binary package manager, in the Jail
* Installs Puppet plus all dependencies in the Jail
* Updates the Jail via "freebsd-update" to the latest version
* Restarts the Jail and invokes Puppet.
* Puppet then also schedules a periodic cron job for the next Puppet runs.

```
admin sun:~ [1951]% sudo /opt/snonux/local/etc/init.d/enc activate sync
Starting jails: dns.
The package management tool is not yet installed on your system.
Do you want to fetch and install it now? [y/N]: y
Bootstrapping pkg from pkg+http://pkg.FreeBSD.org/freebsd:10:x86:64/latest, please wait...
Verifying signature with trusted certificate pkg.freebsd.org.2013102301... done
[sync.ian.buetow.org] Installing pkg-1.7.2...
[sync.ian.buetow.org] Extracting pkg-1.7.2: 100%
Updating FreeBSD repository catalogue...
[sync.ian.buetow.org] Fetching meta.txz: 100%    944 B   0.9kB/s    00:01    
[sync.ian.buetow.org] Fetching packagesite.txz: 100%    5 MiB   5.6MB/s    00:01   
Processing entries: 100%
FreeBSD repository update completed. 25091 packages processed.
Updating database digests format: 100%
The following 20 package(s) will be affected (of 0 checked):

  New packages to be INSTALLED:
          git: 2.7.4_1
          expat: 2.1.0_3
          python27: 2.7.11_1
          libffi: 3.2.1
          indexinfo: 0.2.4
          gettext-runtime: 0.19.7
          p5-Error: 0.17024
          perl5: 5.20.3_9
          cvsps: 2.1_1
          p5-Authen-SASL: 2.16_1
          p5-Digest-HMAC: 1.03_1
          p5-GSSAPI: 0.28_1
          curl: 7.48.0_1
          ca_root_nss: 3.22.2
          p5-Net-SMTP-SSL: 1.03
          p5-IO-Socket-SSL: 2.024
          p5-Net-SSLeay: 1.72
          p5-IO-Socket-IP: 0.37
          p5-Socket: 2.021
          p5-Mozilla-CA: 20160104

          The process will require 144 MiB more space.
          30 MiB to be downloaded.
[sync.ian.buetow.org] Fetching git-2.7.4_1.txz: 100%    4 MiB   3.7MB/s    00:01    
[sync.ian.buetow.org] Fetching expat-2.1.0_3.txz: 100%   98 KiB 100.2kB/s    00:01    
[sync.ian.buetow.org] Fetching python27-2.7.11_1.txz: 100%   10 MiB  10.7MB/s    00:01    
[sync.ian.buetow.org] Fetching libffi-3.2.1.txz: 100%   35 KiB  36.2kB/s    00:01    
[sync.ian.buetow.org] Fetching indexinfo-0.2.4.txz: 100%    5 KiB   5.0kB/s    00:01    
[sync.ian.buetow.org] Fetching gettext-runtime-0.19.7.txz: 100%  148 KiB 151.1kB/s    00:01    
[sync.ian.buetow.org] Fetching p5-Error-0.17024.txz: 100%   24 KiB  24.8kB/s    00:01    
[sync.ian.buetow.org] Fetching perl5-5.20.3_9.txz: 100%   13 MiB   6.9MB/s    00:02    
[sync.ian.buetow.org] Fetching cvsps-2.1_1.txz: 100%   41 KiB  42.1kB/s    00:01    
[sync.ian.buetow.org] Fetching p5-Authen-SASL-2.16_1.txz: 100%   44 KiB  45.1kB/s    00:01    
[sync.ian.buetow.org] Fetching p5-Digest-HMAC-1.03_1.txz: 100%    9 KiB   9.5kB/s    00:01    
[sync.ian.buetow.org] Fetching p5-GSSAPI-0.28_1.txz: 100%   41 KiB  41.7kB/s    00:01    
[sync.ian.buetow.org] Fetching curl-7.48.0_1.txz: 100%    2 MiB   2.2MB/s    00:01    
[sync.ian.buetow.org] Fetching ca_root_nss-3.22.2.txz: 100%  324 KiB 331.4kB/s    00:01    
[sync.ian.buetow.org] Fetching p5-Net-SMTP-SSL-1.03.txz: 100%   11 KiB  10.8kB/s    00:01    
[sync.ian.buetow.org] Fetching p5-IO-Socket-SSL-2.024.txz: 100%  153 KiB 156.4kB/s    00:01    
[sync.ian.buetow.org] Fetching p5-Net-SSLeay-1.72.txz: 100%  234 KiB 239.3kB/s    00:01    
[sync.ian.buetow.org] Fetching p5-IO-Socket-IP-0.37.txz: 100%   27 KiB  27.4kB/s    00:01    
[sync.ian.buetow.org] Fetching p5-Socket-2.021.txz: 100%   37 KiB  38.0kB/s    00:01    
[sync.ian.buetow.org] Fetching p5-Mozilla-CA-20160104.txz: 100%  147 KiB 150.8kB/s    00:01    
Checking integrity...
[sync.ian.buetow.org] [1/12] Installing libyaml-0.1.6_2...
[sync.ian.buetow.org] [1/12] Extracting libyaml-0.1.6_2: 100%
[sync.ian.buetow.org] [2/12] Installing libedit-3.1.20150325_2...
[sync.ian.buetow.org] [2/12] Extracting libedit-3.1.20150325_2: 100%
[sync.ian.buetow.org] [3/12] Installing ruby-2.2.4,1...
[sync.ian.buetow.org] [3/12] Extracting ruby-2.2.4,1: 100%
[sync.ian.buetow.org] [4/12] Installing ruby22-gems-2.6.2...
[sync.ian.buetow.org] [4/12] Extracting ruby22-gems-2.6.2: 100%
[sync.ian.buetow.org] [5/12] Installing libxml2-2.9.3...
[sync.ian.buetow.org] [5/12] Extracting libxml2-2.9.3: 100%
[sync.ian.buetow.org] [6/12] Installing dmidecode-3.0...
[sync.ian.buetow.org] [6/12] Extracting dmidecode-3.0: 100%
[sync.ian.buetow.org] [7/12] Installing rubygem-json_pure-1.8.3...
[sync.ian.buetow.org] [7/12] Extracting rubygem-json_pure-1.8.3: 100%
[sync.ian.buetow.org] [8/12] Installing augeas-1.4.0...
[sync.ian.buetow.org] [8/12] Extracting augeas-1.4.0: 100%
[sync.ian.buetow.org] [9/12] Installing rubygem-facter-2.4.4...
[sync.ian.buetow.org] [9/12] Extracting rubygem-facter-2.4.4: 100%
[sync.ian.buetow.org] [10/12] Installing rubygem-hiera1-1.3.4_1...
[sync.ian.buetow.org] [10/12] Extracting rubygem-hiera1-1.3.4_1: 100%
[sync.ian.buetow.org] [11/12] Installing rubygem-ruby-augeas-0.5.0_2...
[sync.ian.buetow.org] [11/12] Extracting rubygem-ruby-augeas-0.5.0_2: 100%
[sync.ian.buetow.org] [12/12] Installing puppet38-3.8.4_1...
===> Creating users and/or groups.
Creating group 'puppet' with gid '814'.
Creating user 'puppet' with uid '814'.
[sync.ian.buetow.org] [12/12] Extracting puppet38-3.8.4_1: 100%
.
.
.
.
.
Looking up update.FreeBSD.org mirrors... 4 mirrors found.
Fetching public key from update4.freebsd.org... done.
Fetching metadata signature for 10.1-RELEASE from update4.freebsd.org... done.
Fetching metadata index... done.
Fetching 2 metadata files... done.
Inspecting system... done.
Preparing to download files... done.
Fetching 874 patches.....10....20....30....
.
.
.
Applying patches... done.
Fetching 1594 files... 
Installing updates...
done.
Info: Loading facts
Info: Loading facts
Info: Loading facts
Info: Loading facts
Could not retrieve fact='pkgng_version', resolution='<anonymous>': undefined method `pkgng_enabled' for Facter:Module
Warning: Config file /usr/local/etc/puppet/hiera.yaml not found, using Hiera defaults
Notice: Compiled catalog for sync.ian.buetow.org in environment production in 1.31 seconds
Warning: Found multiple default providers for package: pkgng, gem, pip; using pkgng
Info: Applying configuration version '1460192563'
Notice: /Stage[main]/S_base_freebsd/User[root]/shell: shell changed '/bin/csh' to '/bin/tcsh'
Notice: /Stage[main]/S_user::Root_files/S_user::All_files[root_user]/File[/root/user]/ensure: created
Notice: /Stage[main]/S_user::Root_files/S_user::My_files[root]/File[/root/userfiles]/ensure: created
Notice: /Stage[main]/S_user::Root_files/S_user::My_files[root]/File[/root/.task]/ensure: created
.
.
.
.
Notice: Finished catalog run in 206.09 seconds
```

## Managing multiple Jails

Of course I am operating multiple Jails on the same host this way with Puppet:

* A Jail for the MTA
* A Jail for the Webserver
* A Jail for BIND DNS server
* A Jail for syncing data forth and back between various servers
* A Jail for other personal (experimental) use
* ...etc

All done in a pretty automated manor. 

E-Mail me your thoughts at comments@mx.buetow.org!

[Go back to the main site](../)  