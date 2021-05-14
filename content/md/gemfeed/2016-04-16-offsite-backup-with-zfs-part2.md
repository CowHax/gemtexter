# Offsite backup with ZFS (Part 2)

```
 ________________
|# :           : #|
|  : ZFS/GELI  :  |________________ 
|  :   Offsite : |# :           : #|
|  :  Backup 1 : |  : ZFS/GELI  :  |
|  :___________: |  :   Offsite :  |
|     _________  |  :  Backup 2 :  |
|    | __      | |  :___________:  |
|    ||  |     | |     _________   |
\____||__|_____|_|    | __      |  |
                 |    ||  |     |  |
                 \____||__|_____|__|
```

> Written by Paul Buetow 2016-04-16

[Read the first part before reading any furter here...](./2016-04-03-offsite-backup-with-zfs.md)  

I enhanced the procedure a bit. From now on I am having two external 2TB USB hard drives. Both are setup exactly the same way. To decrease the probability that they will not fail at about the same time both drives are of different brands. One drive is kept at the secret location. The other one is kept at home right next to my HP MicroServer.

Whenever I am updating offsite backup, I am doing it to the drive which is kept locally. Afterwards I bring it to the secret location and swap the drives and bring the other one back home. This ensures that I will always have an offiste backup available at a different location than my home - even while updating one copy of it.

Furthermore, I added scrubbing (*zpool scrub...*) to the script. It ensures that the file system is consistent and that there are no bad blocks on the disk and the file system. To increase the reliability I also run a *zfs set copies=2 zroot*. That setting is also synchronized to the offsite ZFS pool. ZFS stores every data block to disk twice now. Yes, it consumes twice as much disk space but it makes it better fault tolerant against hardware errors (e.g. only individual disk sectors going bad). 

E-Mail me your thoughts at comments@mx.buetow.org!

[Go back to the main site](../)  