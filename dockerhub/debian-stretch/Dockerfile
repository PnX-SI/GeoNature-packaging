FROM debian:stretch
MAINTAINER Joel CLEMENT <joelclems@gmail.com>

# ARG URL
# ARG VCS_URL
# ARG VCS_REF
# ARG BUILD_DATE

LABEL org.label-schema.name="Debian 9 Stretch whith sudo" \
      org.label-schema.description="Debian 9 Stretch whith sudo Docker base image" \
      org.label-schema.vendor="Joel CLEMENT" \
      org.label-schema.license="MIT" \
    #   org.label-schema.url=$URL \
    #   org.label-schema.vcs-url=$VCS_URL \
    #   org.label-schema.vcs-ref=$VCS_REF \
    #   org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.schema-version="1.0"


RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       apt-utils \
       sudo \
    && rm -rf /var/lib/apt/lists/*

COPY sources.list /etc/apt/sources.list