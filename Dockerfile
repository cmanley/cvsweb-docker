FROM alpine:3.8

LABEL Maintainer="Craig Manley https://github.com/cmanley" \
      Description="cvsweb 3.0.6-8 (CVS repository viewer) using nginx, fcgiwrap, and Alpine 3.8"

RUN apk update \
	&& apk --no-cache add \
	cvs \
	fcgiwrap \
	nginx \
	perl \
	perl-ipc-run \
	perl-mime-types \
	perl-uri \
	shadow \
	spawn-fcgi \
	supervisor \
	tzdata \
	&& apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ rcs
# Note: the last package (rcs) doesn't exist in 3.8 yet


### Repository mount point and dummy repository (requires cvs 1.11) ###
ARG REPOSITORY_ROOT=/repos
ARG REPOSITORY_DUMMY=$REPOSITORY_ROOT/If_you_see_this_then_the_host_volume_was_not_mounted
RUN mkdir -p "$REPOSITORY_DUMMY" \
	&& CVSUMASK=022 cvs -d "$REPOSITORY_DUMMY" init


#### CVS ###
#ARG CVS_VERSION=1.12.13
#ARG CVS_BASENAME=cvs-$CVS_VERSION
#ARG CVS_DOWNLOAD_FILE=$CVS_BASENAME.tar.bz2
#ARG CVS_DOWNLOAD_URL=https://ftp.gnu.org/non-gnu/cvs/source/feature/$CVS_VERSION/$CVS_DOWNLOAD_FILE
#ARG CVS_DOWNLOAD_SHA256=78853613b9a6873a30e1cc2417f738c330e75f887afdaf7b3d0800cb19ca515e
#RUN printf "\n########## Building CVS (be patient with the 1 minute wait testing for mktime) ##########\n" \
#	&& NEED='g++ make wget' \
#	&& DEL='' \
#	&& for x in $NEED; do \
#		if [ $(apk list "$x" | grep -F [installed] | wc -l) -eq 0 ]; then \
#			DEL="$DEL $x" \
#			&& echo "Add temporary package $x" \
#			&& apk --no-cache add $x; \
#		fi; \
#	done \
#	&& cd /tmp \
#	&& wget -q "$CVS_DOWNLOAD_URL" -O "$CVS_DOWNLOAD_FILE" \
#	&& sha256sum "$CVS_DOWNLOAD_FILE" \
#	&& echo "$CVS_DOWNLOAD_SHA256  $CVS_DOWNLOAD_FILE" | sha256sum -c - \
#	&& tar -xf "$CVS_DOWNLOAD_FILE" \
#	&& rm -fr "$CVS_DOWNLOAD_FILE" \
#	&& cd "$CVS_BASENAME" \
#	&& ./configure --prefix=/usr --disable-nls \
#	&& make --quiet install \
#	&& cd - \
#	&& rm -fr "$CVS_BASENAME" \
#	&& rm -fr /usr/share/man \
#	&& if [ -n "$DEL" ]; then echo "Delete temporary package(s) $DEL" && apk del $DEL; fi


COPY copy /


### Enscript ###
ARG ENSCRIPT_VERSION=1.6.6
ARG ENSCRIPT_BASENAME=enscript-$ENSCRIPT_VERSION
ARG ENSCRIPT_DOWNLOAD_FILE=$ENSCRIPT_BASENAME.tar.gz
ARG ENSCRIPT_DOWNLOAD_URL=http://ftp.gnu.org/gnu/enscript/$ENSCRIPT_DOWNLOAD_FILE
ARG ENSCRIPT_DOWNLOAD_SHA256=6d56bada6934d055b34b6c90399aa85975e66457ac5bf513427ae7fc77f5c0bb
RUN printf "\n########## Building Enscript (just ignore the warnings) ##########\n" \
	&& NEED='g++ make wget' \
	&& DEL='' \
	&& for x in $NEED; do \
		if [ $(apk list "$x" | grep -F [installed] | wc -l) -eq 0 ]; then \
			DEL="$DEL $x" \
			&& echo "Add temporary package $x" \
			&& apk --no-cache add $x; \
		fi; \
	done \
	&& cd /tmp \
	&& wget -q "$ENSCRIPT_DOWNLOAD_URL" -O "$ENSCRIPT_DOWNLOAD_FILE" \
	&& sha256sum "$ENSCRIPT_DOWNLOAD_FILE" \
	&& echo "$ENSCRIPT_DOWNLOAD_SHA256  $ENSCRIPT_DOWNLOAD_FILE" | sha256sum -c - \
	&& tar -xf "$ENSCRIPT_DOWNLOAD_FILE" \
	&& rm -fr "$ENSCRIPT_DOWNLOAD_FILE" \
	&& cd "$ENSCRIPT_BASENAME" \
	&& ./configure --prefix=/usr --disable-nls \
	&& make --quiet install \
	&& cd - \
	&& rm -fr "$ENSCRIPT_BASENAME" \
	&& rm -fr /usr/share/info \
	&& if [ -n "$DEL" ]; then echo "Delete temporary package(s) $DEL" && apk del $DEL; fi
# Add php highlighting support to enscript
#RUN if [ -d /usr/share/enscript/hl ] && [ ! -f /usr/share/enscript/hl/php.st ]; then wget -q -O /usr/share/enscript/hl/php.st https://raw.githubusercontent.com/gooselinux/enscript/master/enscript-php-1.6.4.st; fi


### cvsgraph (optional) ###
ARG CVSGRAPH_VERSION=1.7.0
ARG CVSGRAPH_BASENAME=cvsgraph-$CVSGRAPH_VERSION
ARG CVSGRAPH_DOWNLOAD_FILE=$CVSGRAPH_BASENAME.tar.gz
#ARG CVSGRAPH_DOWNLOAD_URL=http://www.akhphd.au.dk/~bertho/cvsgraph/release/$CVSGRAPH_DOWNLOAD_FILE
ARG CVSGRAPH_DOWNLOAD_URL=https://github.com/cmanley/cvsweb-docker/raw/alpine/$CVSGRAPH_DOWNLOAD_FILE
ARG CVSGRAPH_DOWNLOAD_SHA256=74438faaefd325c7a8ed289ea5d1657befe1d1859d55f8fbbcc7452f4efd435f
RUN printf "\n########## Building cvsgraph ##########\n" \
	&& cd /tmp \
	&& apk --no-cache add libgd \
	&& NEED='byacc flex gd-dev g++ make freetype-dev libjpeg-turbo-dev libpng-dev libwebp-dev wget' \
	&& DEL='' \
	&& for x in $NEED; do \
		apk list "$x"; \
		if [ $(apk list "$x" | grep -F [installed] | wc -l) -eq 0 ]; then \
			DEL="$DEL $x" \
			&& echo "Add temporary package $x" \
			&& apk --no-cache add $x; \
		fi; \
		echo $?; \
	done \
	&& wget -q "$CVSGRAPH_DOWNLOAD_URL" -O "$CVSGRAPH_DOWNLOAD_FILE" \
	&& sha256sum "$CVSGRAPH_DOWNLOAD_FILE" \
	&& echo "$CVSGRAPH_DOWNLOAD_SHA256  $CVSGRAPH_DOWNLOAD_FILE" | sha256sum -c - \
	&& tar -xf "$CVSGRAPH_DOWNLOAD_FILE" \
	&& rm -fr "$CVSGRAPH_DOWNLOAD_FILE" \
	&& cd "$CVSGRAPH_BASENAME" \
	&& ./configure --prefix=/usr sysconfdir=/etc/cvsgraph --disable-nls \
	&& make --quiet install \
	&& mkdir -p /etc/cvsgraph \
	&& cp cvsgraph.conf /etc/cvsgraph/ \
	&& cd - \
	&& rm -fr "$CVSGRAPH_BASENAME" \
	&& rm -fr /usr/share/man \
	&& if [ -n "$DEL" ]; then echo "Delete temporary package(s) $DEL" && apk del $DEL; fi


### cvsweb from Debian ###
ARG CVSWEB_DOWNLOAD_FILE=cvsweb_3.0.6-8_all.deb
ARG CVSWEB_DOWNLOAD_URL=http://ftp.debian.org/debian/pool/main/c/cvsweb/$CVSWEB_DOWNLOAD_FILE
ARG CVSWEB_DOWNLOAD_SHA256=057488d7dcc47bba38cdc1446793641834dca489cc83a300437149f7f1fcc083
RUN printf "\n########## Installing cvsweb ##########\n" \
	&& NEED='binutils patch wget' \
	&& DEL='' \
	&& for x in $NEED; do \
		if [ $(apk list "$x" | grep -F [installed] | wc -l) -eq 0 ]; then \
			DEL="$DEL $x" \
			&& echo "Add temporary package $x" \
			&& apk --no-cache add $x; \
		fi; \
	done \
	&& cd /tmp \
	&& wget -q "$CVSWEB_DOWNLOAD_URL" -O "$CVSWEB_DOWNLOAD_FILE" \
	&& sha256sum "$CVSWEB_DOWNLOAD_FILE" \
	&& echo "$CVSWEB_DOWNLOAD_SHA256  $CVSWEB_DOWNLOAD_FILE" | sha256sum -c - \
	&& ar x "$CVSWEB_DOWNLOAD_FILE" data.tar.xz && rm "$CVSWEB_DOWNLOAD_FILE" \
	&& tar -xf data.tar.xz -C / ./usr ./etc && rm data.tar.xz \
	&& ln -s /usr/share/cvsweb /var/www/cvsweb \
	&& mkdir /var/www/cvsweb/cgi-bin \
	&& ln -s /usr/lib/cgi-bin/cvsweb /var/www/cvsweb/cgi-bin/cvsweb.cgi \
	&& patch /usr/lib/cgi-bin/cvsweb /usr/lib/cgi-bin/cvsweb.favicon.patch && $(rm /usr/lib/cgi-bin/cvsweb.orig 2>/dev/null || /bin/true) \
	&& patch /etc/cvsweb/cvsweb.conf /etc/cvsweb/enable-confd.patch        && $(rm /usr/lib/cgi-bin/cvsweb.orig 2>/dev/null || /bin/true) \
	&& if [ -n "$DEL" ]; then echo "Delete temporary package(s) $DEL" && apk del $DEL; fi


# Use the same fcgiwrap path as in Debian so that the same supervisord.conf file can be used
RUN ln -s /usr/bin/fcgiwrap /usr/sbin/fcgiwrap

# Add the Debian default user required by nginx and fcgiwrap
RUN adduser -D -S -u 82 -h /var/www -G www-data www-data


EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["cvsweb:alpine"]
