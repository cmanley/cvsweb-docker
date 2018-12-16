FROM debian:stretch-slim

LABEL Maintainer="Craig Manley https://github.com/cmanley" \
      Description="cvsweb 3.0.6-8 (CVS repository viewer) using nginx, fcgiwrap, and Debian stretch-slim"

RUN apt-get update && apt-get install -y \
	cvsgraph \
	cvsweb \
	enscript \
	fcgiwrap \
	libcompress-zlib-perl \
	libmime-types-perl \
	nginx-light \
	patch \
	supervisor \
	&& rm -rf /var/lib/apt/lists/*


### repository mount point and dummy repository ###
ARG REPOSITORY_ROOT=/repos
ARG REPOSITORY_DUMMY=$REPOSITORY_ROOT/If_you_see_this_then_the_host_volume_was_not_mounted
RUN mkdir -p "$REPOSITORY_DUMMY" \
	&& cd "$REPOSITORY_DUMMY" \
	&& CVSUMASK=022 cvs -d "$REPOSITORY_DUMMY" init \
	&& cd -;


COPY copy /


### Configure cvsweb ####
#RUN sed -Ei "s/^if \(0\) \{$/if (1) {/" /etc/cvsweb/cvsweb.conf
#RUN sed -Ei "s|^( *'local' *=> *\[')Local Repository(', *')/var/lib/cvs('\],)|\1Repositories\2${REPOS_ROOT}\3|" /etc/cvsweb/cvsweb.conf
RUN ln -s /usr/share/cvsweb /var/www/cvsweb \
	&& mkdir /var/www/cvsweb/cgi-bin \
	&& ln -s /usr/lib/cgi-bin/cvsweb /var/www/cvsweb/cgi-bin/cvsweb.cgi \
	&& patch /usr/lib/cgi-bin/cvsweb /usr/lib/cgi-bin/cvsweb.favicon.patch \
	&& patch /etc/cvsweb/cvsweb.conf /etc/cvsweb/enable-confd.patch


# Add PHP highlighting support to enscript
#RUN if [ -d /usr/share/enscript/hl ] && [ ! -f /usr/share/enscript/hl/php.st ]; then \
#		curl -Ss https://raw.githubusercontent.com/gooselinux/enscript/master/enscript-php-1.6.4.st --output /usr/share/enscript/hl/php.st \
#	fi


EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["cvsweb"]
