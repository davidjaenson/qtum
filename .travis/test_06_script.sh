#!/usr/bin/env bash
#
# Copyright (c) 2018 The Bitcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

export LC_ALL=C.UTF-8

TRAVIS_COMMIT_LOG=$(git log --format=fuller -1)
export TRAVIS_COMMIT_LOG

OUTDIR=$BASE_OUTDIR/$TRAVIS_PULL_REQUEST/$TRAVIS_JOB_NUMBER-$HOST
QTUM_CONFIG_ALL=""
if [ -z "$NO_DEPENDS" ]; then
  DOCKER_EXEC ccache --max-size=$CCACHE_SIZE
fi

BEGIN_FOLD autogen
if [ -n "$CONFIG_SHELL" ]; then
  DOCKER_EXEC "$CONFIG_SHELL" -c "./autogen.sh"
else
  DOCKER_EXEC ./autogen.sh
fi
END_FOLD

BEGIN_FOLD configure
DOCKER_EXEC ./configure --cache-file=../config.cache $QTUM_CONFIG_ALL $QTUM_CONFIG || ( cat config.log && false)
END_FOLD

BEGIN_FOLD build
DOCKER_EXEC make $MAKEJOBS $GOAL || ( echo "Build failure. Verbose build follows." && DOCKER_EXEC make $GOAL V=1 ; false )
END_FOLD

if [ "$RUN_UNIT_TESTS" = "true" ]; then
  BEGIN_FOLD unit-tests
  DOCKER_EXEC LD_LIBRARY_PATH=$TRAVIS_BUILD_DIR/depends/$HOST/lib make $MAKEJOBS check VERBOSE=1
  END_FOLD
fi

if [ "$TRAVIS_EVENT_TYPE" = "cron" ]; then
  extended="--extended --exclude feature_pruning,feature_assumevalid,feature_bip68_sequence,feature_cltv,feature_dbcrash,feature_dersig,feature_fee_estimation,feature_maxuploadtarget,feature_rbf,mempool_packages,p2p_feefilter,p2p_unrequested_blocks"
fi

if [ "$RUN_FUNCTIONAL_TESTS" = "true" ]; then
  BEGIN_FOLD functional-tests
  DOCKER_EXEC test/functional/test_runner.py --combinedlogslen=500 --coverage --quiet --exclude qtum_callcontract_timestamp,wallet_txn_clone,rpc_psbt,qtum_pos,p2p_compactblocks,feature_nulldummy,wallet_multiwallet,feature_block,p2p_segwit,qtum_ignore_mpos_participant_reward,qtum_opcall,qtum_pos_conflicting_txs,wallet_bumpfee ${extended} ${FUNCTIONAL_TESTS_CONFIG}
  END_FOLD
fi
