#! /bin/bash

# Copyright 2011 Peter Williams <peter@newton.cx>
#
# This file is part of miriad-mirroring.
#
# miriad-mirroring is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# miriad-mirroring is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with miriad-mirroring.  If not, see
# <http://www.gnu.org/licenses/>.

# Intended to be run from cron, so tries to produce no output
# under normal circumstances.

url='ftp://ftp.atnf.csiro.au/pub/software/miriad/miriad-rcs.tar.gz'
set -e

# Configuration (such as it is). Requires $ATNF_GIT_DIR

cfg=$(dirname $0)/setup.sh

if [ ! -f $cfg ] ; then
    echo "Error: need configuration file $cfg" >&2
    exit 1
fi

source $cfg

if [ -z "$ATNF_GIT_DIR" ] ; then
    echo "Error: config file $cfg must set \$ATNF_GIT_DIR" >&2
    exit 1
fi

# Download daily RCS export; create fake CVS repo; git cvsimport

export GIT_DIR=$ATNF_GIT_DIR
authfile=$(cd $(dirname $0) && pwd)/atnf-authors.txt

work=$(mktemp -d)
export CVSROOT=$work/cvsroot
log=$work/cvsimport.log

cd $work
curl -s "$url" |tar xz
cvs init
ln -s ../miriad/.rcs cvsroot/miriad
git cvsimport -o CVSHEAD -i -a -k -A $authfile miriad >$log 2>&1
# Need to "|| true" the greps because of the "set -e"
grep -v '^branch .* not found in global branch hash' <$log | \
  grep -v '^Skipping ' | \
  grep -v '^\* UNKNOWN LINE \* Branches' || true
git gc --quiet
rm -rf $work
