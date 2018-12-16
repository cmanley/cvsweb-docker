cvsweb-docker
=============

A Docker image of CVSweb 3.0.6-8 (an old CVS repository viewer) based on nginx and Alpine Linux 3.8
with configurable run-time options (such as timezone and group id).

You can use it to quickly and safely expose a web interface to the CVS repositories directory on your host machine.

**Quick note**: If you haven't heard about [ViewVC](https://github.com/viewvc/viewvc/) before, then you may want to look at that project too because it's a CVS repository viewer inspired by CVSweb, for which a [Docker image](https://github.com/cmanley/viewvc-docker) project exists too.

Alpine Linux related notes
--------------------------
The Dockerfile uses the cvsweb 3.0.6-8 Debian package which is a patched version of the last release from https://people.freebsd.org/~scop/cvsweb/
The cvsweb annotate function does not work yet on repositories created with CVS version 1.12.
The reason is because the Alpine cvs package is version 1.11 which and doesn't recognize the `UseNewInfoFmtStrings=yes` lines in `CVSROOT/config` files.
Compiling CVS 1.12.13 from source solved that, but introduced other problems instead.

Installation
------------

### Option 1: Download image from hub.docker.com ###
You can simply pull this image from docker hub like this:

	docker pull cmanley/cvsweb:alpine

If you want to, then you can create a shorter tag (alias) for the image using this command:

	docker tag cmanley/cvsweb:alpine cvsweb

With the shorter tag, you can replace the last argument `cmanley/cvsweb` (the image name) with `cvsweb`
in all the `docker run` commands listed under the header *Usage examples*.

### Option 2: Build the image yourself ###

	git clone <Link from "Clone or download" button>
	cd cvsweb-docker
	docker build --rm -t cmanley/cvsweb:alpine .

The docker build command must be run as root or as member of the docker group,
or else you'll get the error "permission denied while trying to connect to the Docker daemon socket".

Usage examples
--------------

Assuming that your cvs repository root directory on the host machine is `/var/lib/cvs`
and has the privileges 750 (user may read+write, group can only read, and others are denied),
and that you want cvsweb be accessible on `127.0.0.1:8080`, then execute one of the commands below.
You may want to place your preferred command in an shell alias or script to not have to type it out each time.

Minimal:

	docker run --name cvsweb -v /var/lib/cvs:/repos:ro -p 127.0.0.1:8080:80/tcp --rm -d cmanley/cvsweb:alpine

Recommended use (use the same time zone as the host):

	docker run --name cvsweb \
	-v /var/lib/cvs:/repos:ro \
	-p 127.0.0.1:8080:80 \
	-e TZ=$(</etc/timezone) \
	--rm -d cmanley/cvsweb:alpine

Explicitly specify which group id to use for reading the repository, and the timezone:

	docker run --name cvsweb \
	-v /var/lib/cvs:/repos:ro \
	-p 127.0.0.1:8080:80/tcp \
	-e CVSWEB_GID=$(stat -c%g /var/lib/cvs) \
	-e TZ=$(</etc/timezone) \
	--rm -d cmanley/cvsweb:alpine

Start container and a shell session within it (this does not start nginx):

	docker run --name cvsweb \
	-v /var/lib/cvs:/repos:ro \
	-p 127.0.0.1:8080:80/tcp \
	--rm -it cmanley/cvsweb:alpine /bin/sh

In case of problems, start the container without the --rm option, check your docker logs, and check that the container is running:

	docker logs cvsweb
	docker ps

Stop the container using:

	docker stop cvsweb

Remove the container (in case you didn't run it with the --rm option) using:

	docker rm cvsweb

Runtime configuration
---------------------

### Using environment variables ###

You can configure how the container runs by passing some of the environment variables below using the --env or -e option to docker run.
Unless your host's repository is world-readable (which it shouldn't be), then you'll need to at least need to specify CVSWEB_GID.

| name              | description                                                                                                      |
|-------------------|------------------------------------------------------------------------------------------------------------------|
| **CVSWEB_DEBUG**  | Allowed values: true or false (default).                                                                         |
| **CVSWEB_GID**    | The gid (group id) of the host repository directory. If not given, then the gid of the host volume will be used. |
| **TZ**            | Specify the time zone to use. Default is UTC. In most cases, use the value in the host's /etc/timezone file.     |

### Using override config files ###

Besides simply editing existing config files in the project and then rebuilding and running the project, 
you can also create override config files on you host machine and mount them into the container at run time.

#### Example: ####

If you want to tweak the visual options of cvsweb such as hiding the "Author" column in the files overview pages, and show white-space changes in diffs, then:

* Create a file with any name as long as it has the extension .conf, e.g. `custom.conf` containing the lines:
```perl
$hr_ignwhite = 0;
$show_author = 0;
1;	# This file uses Perl syntax just like cvsweb.conf and must therefore end with "1;"
```
* Take note of the full path to the cvsweb conf.d directory in the image. That is `/etc/cvsweb/conf.d/`.
* Mount your file into the container using the option `-v /path/to/custom.conf:/etc/cvsweb/conf.d/custom.conf:ro` when running it like this:
```shell
docker run --name cvsweb \
-v /path/to/custom.conf:/etc/cvsweb/conf.d/custom.conf:ro
-v /var/lib/cvs:/repos:ro \
-p 127.0.0.1:8080:80 \
-e TZ=$(</etc/timezone) \
--rm -d cmanley/cvsweb:alpine
```
Tip: Leave the -d (= detach = run in background) option off the first time you run your new command just to see if your change causes any errors.

Security information
--------------------

* nginx runs as www-data:www-data and forwards requests to fcgiwrap which executes the cvsweb code.
* fcgiwrap runs with uid www-data and with the gid of the CVSWEB_GID environment variable if given, else with gid of the host volume.
* It's important to always protect your host's volume by adding the ":ro" attribute to the docker run -v option as in the examples above.
