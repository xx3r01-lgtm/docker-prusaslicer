# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie

# set version label
ARG BUILD_DATE
ARG VERSION
ARG PRUSASLICER_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# title
ENV TITLE=PrusaSlicer \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    PIXELFLUX_WAYLAND=true

RUN \
  echo "**** add icon ****" && \
  curl -o \
    /usr/share/selkies/www/icon.png -L \
    https://raw.githubusercontent.com/prusa3d/PrusaSlicer/refs/heads/master/resources/icons/PrusaSlicer_128px.png && \
  cp /usr/share/selkies/www/icon.png /usr/share/pixmaps/prusaslicer.png && \
  echo "**** add mozilla apt repo ****" && \
  install -d -m 0755 /etc/apt/keyrings && \
  curl -o \
    /etc/apt/keyrings/packages.mozilla.org.asc -L \
    https://packages.mozilla.org/apt/repo-signing-key.gpg && \
  echo \
    "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" > \
    /etc/apt/sources.list.d/mozilla.list && \
  printf \
    "Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n" > \
    /etc/apt/preferences.d/mozilla && \
  echo "**** install packages ****" && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install --no-install-recommends -y \
    firefox \
    gstreamer1.0-alsa \
    gstreamer1.0-gl \
    gstreamer1.0-gtk3 \
    gstreamer1.0-libav \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-pulseaudio \
    gstreamer1.0-qt5 \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    libgstreamer-plugins-bad1.0 \
    libmspack0 \
    libwebkit2gtk-4.1-0 \
    libwx-perl && \
  echo "**** install prusaslicer from appimage ****" && \
  RELEASE_JSON=$(curl -sX GET "https://api.github.com/repos/gneiss15/PrusaSlicer.AppImage/releases/latest") && \
  if [ -z ${PRUSASLICER_VERSION+x} ]; then \
    PRUSASLICER_VERSION=$(echo "${RELEASE_JSON}" | jq -r '.tag_name'); \
  fi && \
  DOWNLOAD_URL=$(echo "${RELEASE_JSON}" | jq -r 'first(.assets[].browser_download_url | select(test("x86_64.*\\.AppImage$")))') && \
  cd /tmp && \
  curl -o \
    /tmp/prusa.app -L \
    "${DOWNLOAD_URL}" && \
  chmod +x /tmp/prusa.app && \
  ./prusa.app --appimage-extract && \
  mv squashfs-root /opt/prusaslicer && \
  localedef -i en_GB -f UTF-8 en_GB.UTF-8 && \
  find /opt/prusaslicer -type d -exec chmod 755 {} + && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  apt-get autoclean && \
  rm -rf \
    /config/.cache \
    /config/.launchpadlib \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 3001
VOLUME /config
