#!/bin/bash -x

set -o errexit    # abort script at first error

function testPrintVersion() {
  local tagname=$1
  local imagename=$tagname
  docker run --rm motionbank/volumerize:$imagename duplicity -V
}

testPrintVersion $1
