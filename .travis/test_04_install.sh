#!/usr/bin/env bash
#
# Copyright (c) 2018 The Bitcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

export LC_ALL=C.UTF-8

travis_retry docker pull "$DOCKER_NAME_TAG"
env | grep -E '^(BITCOIN_CONFIG|CCACHE_|WINEDEBUG|LC_ALL|BOOST_TEST_RANDOM|CONFIG_SHELL|)' | tee /tmp/env
DOCKER_ID=$(docker run -idt --mount type=bind,src=$TRAVIS_BUILD_DIR,dst=$TRAVIS_BUILD_DIR --mount type=bind,src=$CCACHE_DIR,dst=$CCACHE_DIR -w $TRAVIS_BUILD_DIR --env-file /tmp/env $DOCKER_NAME_TAG)

DOCKER_EXEC () {
  docker exec $DOCKER_ID bash -c "cd $PWD && $*"
}

if [ -n "$DPKG_ADD_ARCH" ]; then
  DOCKER_EXEC dpkg --add-architecture "$DPKG_ADD_ARCH"
fi

travis_retry DOCKER_EXEC apt-get update -qq
travis_retry DOCKER_EXEC apt-get install -qq --no-install-recommends --no-upgrade $PACKAGES $DOCKER_PACKAGES
travis_retry DOCKER_EXEC add-apt-repository -y ppa:bitcoin/bitcoin
travis_retry DOCKER_EXEC apt-get update -qq
travis_retry DOCKER_EXEC apt-get install -qq libdb4.8++-dev

