# Perl Daemon (Service Framework)

```
   a'!   _,,_ a'!   _,,_     a'!   _,,_
     \\_/    \  \\_/    \      \\_/    \.-,
      \, /-( /'-,\, /-( /'-,    \, /-( /
      //\ //\\   //\ //\\       //\ //\\jrei
```

> Written by Paul Buetow 2011-05-07, last updated 2021-05-07

PerlDaemon is a minimal daemon for Linux and other Unix like operating systems programmed in Perl. It is a minimal but pretty functional and fairly generic service framework. This means that it does not do anything useful other than providing a framework for starting, stopping, configuring and logging. In order to do something useful, a module (written in Perl) must be provided.

## Features

PerlDaemon supports:

* Automatic daemonizing
* Logging
* logrotation (via SIGHUP)
* Clean shutdown support (SIGTERM)
* Pid file support (incl. check on startup)
* Easy to configure
* Easy to extend
* Multi instance support (just use a different directory for each instance).

## Quick Guide

```
# Starting
 ./bin/perldaemon start (or shortcut ./control start)

# Stopping
 ./bin/perldaemon stop (or shortcut ./control stop)

# Alternatively: Starting in foreground 
./bin/perldaemon start daemon.daemonize=no (or shortcut ./control foreground)
```

To stop a daemon running in foreground mode "Ctrl+C" must be hit. To see more available startup options run "./control" without any argument.

## How to configure

The daemon instance can be configured in "./conf/perldaemon.conf". If you want to change a property only once, it is also possible to specify it on command line (that then will take precedence over the config file). All available config properties can be viewed via "./control keys":

```
pb@titania:~/svn/utils/perldaemon/trunk$ ./control keys
# Path to the logfile
daemon.logfile=./log/perldaemon.log

# The amount of seconds until the next event look takes place
daemon.loopinterval=1

# Path to the modules dir
daemon.modules.dir=./lib/PerlDaemonModules

# Specifies either the daemon should run in daemon or foreground mode
daemon.daemonize=yes

# Path to the pidfile
daemon.pidfile=./run/perldaemon.pid

# Each module should run every runinterval seconds
daemon.modules.runinterval=3

# Path to the alive file (is touched every loopinterval seconds, usable to monitor)
daemon.alivefile=./run/perldaemon.alive

# Specifies the working directory
daemon.wd=./
```

## Example 

So lets start the daemon with a loop interval of 10 seconds:

```
$ ./control keys | grep daemon.loopinterval
daemon.loopinterval=1
$ ./control keys daemon.loopinterval=10 | grep daemon.loopinterval
daemon.loopinterval=10
$ ./control start daemon.loopinterval=10; sleep 10; tail -n 2 log/perldaemon.log
Starting daemon now...
Mon Jun 13 11:29:27 2011 (PID 2838): Triggering PerlDaemonModules::ExampleModule 
(last triggered before 10.002106s; carry: 7.002106s; wanted interval: 3s)
Mon Jun 13 11:29:27 2011 (PID 2838): ExampleModule Test 2
$ ./control stop
Stopping daemon now...
```

If you want to change that property forever either edit perldaemon.conf or do this:

```
$ ./control keys daemon.loopinterval=10 > new.conf; mv new.conf conf/perldaemon.conf
```

## HiRes event loop

PerlDaemon uses `Time::HiRes` to make sure that all the events run in correct intervals. Each loop run a time carry value is recorded and added to the next loop run in order to catch up lost time.

## Writing your own modules

### Example module

This is one of the example modules you will find in the source code. It should be quite self-explanatory if you know Perl :-).

```
package PerlDaemonModules::ExampleModule;

use strict;
use warnings;

sub new ($$$) {
  my ($class, $conf) = @_;

  my $self = bless { conf => $conf }, $class;

  # Store some private module stuff
  $self->{counter} = 0;

  return $self;
}

# Runs periodically in a loop (set interval in perldaemon.conf)
sub do ($) {
  my $self = shift;
  my $conf = $self->{conf};
  my $logger = $conf->{logger};

  # Calculate some private module stuff
  my $count = ++$self->{counter};

  $logger->logmsg("ExampleModule Test $count");
}

1;
```

### Your own module

Want to give it some better use? It's just a easy as:

```
 cd ./lib/PerlDaemonModules/
 cp ExampleModule.pm YourModule.pm
 vi YourModule.pm
 cd -
 ./bin/perldaemon restart (or shortcurt ./control restart)
```

Now watch `./log/perldaemon.log` closely. It is a good practise to test your modules in 'foreground mode' (see above how to do that).

BTW: You can install as many modules within the same instance as desired. But they are run in sequential order (in future they can also run in parallel using several threads or processes).

## May the source be with you

You can find PerlDaemon (including the examples) at:

[https://github.com/snonux/perldaemon](https://github.com/snonux/perldaemon)  

E-Mail me your thoughts at comments@mx.buetow.org!

[Go back to the main site](../)  