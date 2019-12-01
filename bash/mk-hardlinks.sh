#!/usr/bin/env bash

# Tested on: bsdtar 3.4.0 - libarchive 3.4.0 zlib/1.2.11 liblzma/5.2.4 bz2lib/1.0.8 liblz4/1.9.1

set -ex

mkdir -p test/data/hard-links
echo "shared" > test/data/hard-links/a.txt
ln test/data/hard-links/{a,b}.txt
bsdtar -cvf test/data/hard-links-bsd.tar -C test/data hard-links
rm test/data/hard-links/{a,b}.txt
rmdir test/data/hard-links
