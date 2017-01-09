#!/usr/bin/env bash

set -eux

LAST_LINE=$(stack sdist 2>&1 | tail -n 1)

if [[ "$OS" =~ Windows ]]; then
    # Specify the working dir manually on msys/cygwin because pwd may
    # report a wrongful path (e.g /c/users instead of /c/Users/..)  This
    # would otherswise cause docker (toobox?) to fail mount binding
    # silently.

    WD=/c/Users/jmn/code/halp
    SDIST=$(cygpath -u ${LAST_LINE##* })
    LAST_LINE=$(stack sdist 2>&1 | tail -n 1)
    DISTDIR=$(dirname $SDIST) 
    DISTDIR_RELATIVE=.$(echo $DISTDIR | cut -d. -f2)
    MYSDIST=$WD/$DISTDIR_RELATIVE/$(basename $SDIST)
    SDIST=$MYSDIST
else
    WD=$(pwd)
    SDIST=${LAST_LINE##* }
fi

rm -rf build-static
mkdir build-static
mkdir -p build-home/

docker run --rm \
    -v $WD/build-static:/host-bin \
    -v $SDIST:/sdist.tar.gz \
    -v $WD/build-home:/home/build \
    fpco/docker-static-haskell:8.0.1 \
    /bin/bash -c \
    'chown $(id -u) $HOME && rm -rf $HOME/src && mkdir $HOME/src && cd $HOME/src && tar zxfv /sdist.tar.gz && cd * && stack install --test --system-ghc --local-bin-path /host-bin --ghc-options "-optl-static -fPIC -optc-Os" && upx --best --ultra-brute /host-bin/*'
