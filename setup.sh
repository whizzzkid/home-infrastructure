#!/bin/bash
apt-get install -y              \
    autoconf                    \
    automake                    \
    bison                       \
    build-essential             \
    bzr                         \
    debian-keyring              \
    ed                          \
    flex                        \
    gcc-8-locales               \
    gcc-multilib                \
    gdb                         \
    gdbm-l10n                   \
    git                         \
    libasan5-dbg                \
    libatomic1-dbg              \
    libffi-dev                  \
    libgcc1-dbg                 \
    libgomp1-dbg                \
    libitm1-dbg                 \
    liblsan0-dbg                \
    libmpx2-dbg                 \
    libquadmath0-dbg            \
    libssl-dev                  \
    libstdc++6-8-dbg            \
    libterm-readline-gnu-perl   \
    libtool                     \
    libubsan1-dbg               \
    manpages-dev                \
    openssh-server              \
    python3                     \
    python3-pip                 \
    python3-setuptools          \
    python3-wheel

pip3 -v install docker-compose;
touch ./acme.json && chmod 600 ./acme.json
