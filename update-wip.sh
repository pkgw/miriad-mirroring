#! /bin/bash
#
# Intended to be run from cron, so tries to produce no output
# under normal circumstances.

set -e

# Configuration (such as it is). Requires $WIP_GIT_DIR, $WIP_CVSROOT

cfg=$(dirname $0)/setup.sh

if [ ! -f $cfg ] ; then
    echo "Error: need configuration file $cfg" >&2
    exit 1
fi

source $cfg

if [ -z "$WIP_GIT_DIR" ] ; then
    echo "Error: config file $cfg must set \$WIP_GIT_DIR" >&2
    exit 1
fi

if [ -z "$WIP_CVSROOT" ] ; then
    echo "Error: config file $cfg must set \$WIP_CVSROOT" >&2
    exit 1
fi

# Do the cvsimport.

export CVSROOT="$WIP_CVSROOT"
export GIT_DIR="$WIP_GIT_DIR"
authfile=$(cd $(dirname $0) && pwd)/carma-authors.txt

log=$(mktemp)
git cvsimport -o CVSHEAD -i -a -k -A $authfile wip >$log 2>&1
# Need to "|| true" the greps because of the "set -e"
grep -v '^connect error: Network is unreachable' <$log | \
    grep -v '^cvs rlog: Logging' | \
    grep -v '^branch HEAD not found in global branch hash' | \
    grep -v '^\* UNKNOWN LINE \* Branches' || true
git gc --quiet
git update-server-info
rm $log
