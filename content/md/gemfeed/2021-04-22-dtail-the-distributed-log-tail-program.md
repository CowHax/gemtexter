# DTail - The distributed log tail program

> Written by Paul Buetow 2021-04-22, last updated 2021-04-26

[![DTail logo image](./2021-04-22-dtail-the-distributed-log-tail-program/dtail-logo.png "DTail logo image")](./2021-04-22-dtail-the-distributed-log-tail-program/dtail-logo.png)  

This article first appeared at the Mimecast Engineering Blog but I made it available here in my personal Gemini capsule too.

[Original Mimecast Engineering Blog post at Medium](https://medium.com/mimecast-engineering/dtail-the-distributed-log-tail-program-79b8087904bb)  

Running a large cloud-based service requires monitoring the state of huge numbers of machines, a task for which many standard UNIX tools were not really designed. In this post, I will describe a simple program, DTail, that Mimecast has built and released as Open-Source, which enables us to monitor log files of many servers at once without the costly overhead of a full-blown log management system.

At Mimecast, we run over 10 thousand server boxes. Most of them host multiple microservices and each of them produces log files. Even with the use of time series databases and monitoring systems, raw application logs are still an important source of information when it comes to analysing, debugging, and troubleshooting services.

Every engineer familiar with UNIX or a UNIX-like platform (e.g., Linux) is well aware of tail, a command-line program for displaying a text file content on the terminal which is also especially useful for following application or system log files with tail -f logfile.

Think of DTail as a distributed version of the tail program which is very useful when you have a distributed application running on many servers. DTail is an Open-Source, cross-platform, fairly easy to use, support and maintain log file analysis & statistics gathering tool designed for Engineers and Systems Administrators. It is programmed in Google Go.

## A Mimecast Pet Project

DTail got its inspiration from public domain tools available already in this area but it is a blue sky from-scratch development which was first presented at Mimecast’s annual internal Pet Project competition (awarded with a Bronze prize). It has gained popularity since and is one of the most widely deployed DevOps tools at Mimecast (reaching nearly 10k server installations) and many engineers use it on a regular basis. The Open-Source version of DTail is available at:

[https://dtail.dev](https://dtail.dev)  

Try it out — We would love any feedback. But first, read on…

## Differentiating from log management systems

Why not just use a full-blown log management system? There are various Open-Source and commercial log management solutions available on the market you could choose from (e.g. the ELK stack). Most of them store the logs in a centralized location and are fairly complex to set up and operate. Possibly they are also pretty expensive to operate if you have to buy dedicated hardware (or pay fees to your cloud provider) and have to hire support staff for it.

DTail does not aim to replace any of the log management tools already available but is rather an additional tool crafted especially for ad-hoc debugging and troubleshooting purposes. DTail is cheap to operate as it does not require any dedicated hardware for log storage as it operates directly on the source of the logs. It means that there is a DTail server installed on all server boxes producing logs. This decentralized comes with the direct advantages that there is no introduced delay because the logs are not shipped to a central log storage device. The reduced complexity also makes it more robust against outages. You won’t be able to troubleshoot your distributed application very well if the log management infrastructure isn’t working either.

[![DTail sample session animated gif](./2021-04-22-dtail-the-distributed-log-tail-program/dtail.gif "DTail sample session animated gif")](./2021-04-22-dtail-the-distributed-log-tail-program/dtail.gif)  

As a downside, you won’t be able to access any logs with DTail when the server is down. Furthermore, a server can store logs only up to a certain capacity as disks will fill up. For the purpose of ad-hoc debugging, these are not typically issues. Usually, it’s the application you want to debug and not the server. And disk space is rarely an issue for bare metal and VM-based systems these days, with sufficient space for several weeks’ worth of log storage being available. DTail also supports reading compressed logs. The currently supported compression algorithms are gzip and zstd.

## Combining simplicity, security and efficiency

DTail also has a client component that connects to multiple servers concurrently for log files (or any other text files).

The DTail client interacts with a DTail server on port TCP/2222 via SSH protocol and does not interact in any way with the system’s SSH server (e.g., OpenSSH Server) which might be running at port TCP/22 already. As a matter of fact, you don’t need a regular SSH server running for DTail at all. There is no support for interactive login shells at TCP/2222 either, as by design that port can only be used for text data streaming. The SSH protocol is used for the public/private key infrastructure and transport encryption only and DTail implements its own protocol on top of SSH for the features provided. There is no need to set up or buy any additional TLS certificates. The port 2222 can be easily reconfigured if you preferred to use a different one.

The DTail server, which is a single static binary, will not fork an external process. This means that all features are implemented in native Go code (exception: Linux ACL support is implemented in C, but it must be enabled explicitly on compile time) and therefore helping to make it robust, secure, efficient, and easy to deploy. A single client, running on a standard Laptop, can connect to thousands of servers concurrently while still maintaining a small resource footprint.

Recent log files are very likely still in the file system caches on the servers. Therefore, there tends to be a minimal I/O overhead involved.

## The DTail family of commands

Following the UNIX philosophy, DTail includes multiple command-line commands each of them for a different purpose:

* dserver: The DTail server, the only binary required to be installed on the servers involved.
* dtail: The distributed log tail client for following log files.
* dcat: The distributed cat client for concatenating and displaying text files.
* dgrep: The distributed grep client for searching text files for a regular expression pattern.
* dmap: The distributed map-reduce client for aggregating stats from log files.

[![DGrep sample session animated gif](./2021-04-22-dtail-the-distributed-log-tail-program/dgrep.gif "DGrep sample session animated gif")](./2021-04-22-dtail-the-distributed-log-tail-program/dgrep.gif)  

## Usage example

The use of these commands is almost self-explanatory for a person already used to the standard command line in Unix systems. One of the main goals is to make DTail easy to use. A tool that is too complicated to use under high-pressure scenarios (e.g., during an incident) can be quite detrimental.

The basic idea is to start one of the clients from the command line and provide a list of servers to connect to with –servers. You also must provide a path of remote (log) files via –files. If you want to process multiple files per server, you could either provide a comma-separated list of file paths or make use of file system globbing (or a combination of both).

The following example would connect to all DTail servers listed in the serverlist.txt, follow all files with the ending .log and filter for lines containing the string error. You can specify any Go compatible regular expression. In this example we add the case-insensitive flag to the regex:

```
dtail –servers serverlist.txt –files ‘/var/log/*.log’ –regex ‘(?i:error)’
```

You usually want to specify a regular expression as a client argument. This will mean that responses are pre-filtered for all matching lines on the server-side and thus sending back only the relevant lines to the client. If your logs are growing very rapidly and the regex is not specific enough there might be the chance that your client is not fast enough to keep up processing all of the responses. This could be due to a network bottleneck or just as simple as a slow terminal emulator displaying the log lines on the client-side.

A green 100 in the client output before each log line received from the server always indicates that there were no such problems and 100% of all log lines could be displayed on your terminal (have a look at the animated Gifs in this post). If the percentage falls below 100 it means that some of the channels used by the servers to send data to the client are congested and lines were dropped. In this case, the color will change from green to red. The user then could decide to run the same query but with a more specific regex.

You could also provide a comma-separated list of servers as opposed to a text file. There are many more options you could use. The ones listed here are just the very basic ones. There are more instructions and usage examples on the GitHub page. Also, you can study even more of the available options via the –help switch (some real treasures might be hidden there).

## Fitting it in

DTail integrates nicely into the user management of existing infrastructure. It follows normal system permissions and does not open new “holes” on the server which helps to keep security departments happy. The user would not have more or less file read permissions than he would have via a regular SSH login shell. There is a full SSH key, traditional UNIX permissions, and Linux ACL support. There is also a very low resource footprint involved. On average for tailing and searching log files less than 100MB RAM and less than a quarter of a CPU core per participating server are required. Complex map-reduce queries on big data sets will require more resources accordingly.

## Advanced features

The features listed here are out of the scope of this blog post but are worthwhile to mention:

* Distributed map-reduce queries on stats provided in log files with dmap. dmap comes with its own SQL-like aggregation query language.
* Stats streaming with continuous map-reduce queries. The difference to normal queries is that the stats are aggregated over a specified interval only on the newly written log lines. Thus, giving a de-facto live stat view for each interval.
* Server-side scheduled queries on log files. The queries are configured in the DTail server configuration file and scheduled at certain time intervals. Results are written to CSV files. This is useful for generating daily stats from the log files without the need for an interactive client.
* Server-side stats streaming with continuous map-reduce queries. This for example can be used to periodically generate stats from the logs at a configured interval, e.g., log error counts by the minute. These then can be sent to a time-series database (e.g., Graphite) and then plotted in a Grafana dashboard.
* Support for custom extensions. E.g., for different server discovery methods (so you don’t have to rely on plain server lists) and log file formats (so that map-reduce queries can parse more stats from the logs).

## For the future

There are various features we want to see in the future.

* A spartan mode, not printing out any extra information but the raw remote log files would be a nice feature to have. This will make it easier to post-process the data produced by the DTail client with common UNIX tools. (To some degree this is possible already, just disable the ANSI terminal color output of the client with -noColors and pipe the output to another program).
* Tempting would be implementing the dgoawk command, a distributed version of the AWK programming language purely implemented in Go, for advanced text data stream processing capabilities. There are 3rd party libraries available implementing AWK in pure Go which could be used.
* A more complex change would be the support of federated queries. You can connect to thousands of servers from a single client running on a laptop. But does it scale to 100k of servers? Some of the servers could be used as middleware for connecting to even more servers.
* Another aspect is to extend the documentation. Especially the advanced features such as map-reduce query language and how to configure the server-side queries currently do require more documentation. For now, you can read the code, sample config files or just ask the author for that! But this will be certainly addressed in the future.

## Open Source

Mimecast highly encourages you to have a look at DTail and submit an issue for any features you would like to see. Have you found a bug? Maybe you just have a question or comment? If you want to go a step further: We would also love to see pull requests for any features or improvements. Either way, if in doubt just contact us via the DTail GitHub page.

[https://dtail.dev](https://dtail.dev)  

E-Mail me your thoughts at comments@mx.buetow.org!

[Go back to the main site](../)  