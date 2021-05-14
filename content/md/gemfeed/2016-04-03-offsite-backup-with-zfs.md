# Offsite backup with ZFS

```
 ________________
|# :           : #|
|  : ZFS/GELI  :  |
|  :   Offsite :  |
|  :  Backup   :  |
|  :___________:  |
|     _________   |
|    | __      |  |
|    ||  |     |  |
\____||__|_____|__|
```

> Written by Paul Buetow 2016-04-03

## Please don't lose all my pictures again!

When it comes to data storage and potential data loss I am a paranoid person. It is not just due to my job but also due to a personal experience I encountered over 10 years ago: A single drive failure and loss of all my data (pictures, music, ....).

A little about my personal infrastructure: I am running my own (mostly FreeBSD based) root servers (across several countries: Two in Germany, one in Canada, one in Bulgaria) which store all my online data (E-Mail and my Git repositories). I am syncing incremental (and encrypted) ZFS snapshots between these servers forth and back so either data could be recovered from the other server.

## Local storage box for offline data

Also, I am operating a local server (an HP MicroServer) at home in my apartment. Full snapshots of all ZFS volumes are pulled from the "online" servers to the local server every other week and the incremental ZFS snapshots every day. That local server has a ZFS ZMIRROR with 3 disks configured (local triple redundancy). I keep up to half a year worth of ZFS snapshots of all volumes. That local server also contains all my offline data such as pictures, private documents, videos, books, various other backups, etc.

Once weekly all the data of that local server is copied to two external USB drives as a backup (without the historic snapshots). For simplicity these USB drives are not formatted with ZFS but with good old UFS. This gives me a chance to recover from a (potential) ZFS disaster. ZFS is a complex thing. Sometimes it is good not to trust complex things!

## Storing it at my apartment is not enough

Now I am thinking about an offsite backup of all this local data. The problem is, that all the data remains on a single physical location: My local MicroServer. What happens when the house burns or someone steals my server including the internal disks and the attached USB drives? My first thought was to back up everything to the "cloud". The major issue here is however the limited amount of available upload bandwidth (only 1MBit/s).

The solution is adding another USB drive (2TB) with an encryption container (GELI) and a ZFS pool on it. The GELI encryption requires a secret key and a secret passphrase. I am updating the data to that drive once every 3 months (my calendar is reminding me about it) and afterwards I keep that drive at a secret location outside of my apartment. All the information needed to decrypt (mounting the GELI container) is stored at another (secure) place. Key and passphrase are kept at different places though. Even if someone would know of it, he would not be able to decrypt it as some additional insider knowledge would be required as well.

## Walking one round less

I am thinking of buying a second 2TB USB drive and to set it up the same way as the first one. So I could alternate the backups. One drive would be at the secret location, and the other drive would be at home. And these drives would swap location after each cycle. This would give some security about the failure of that drive and I would have to go to the secret location only once (swapping the drives) instead of twice (picking that drive up in order to update the data + bringing it back to the secret location).

E-Mail me your thoughts at comments@mx.buetow.org!

[Go back to the main site](../)  