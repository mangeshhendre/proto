#!/bin/bash

find sgt -type f -name \*.proto | xargs -n 1 protoc --go_out=$GOPATH/src
find services -type f -name \*.proto | xargs -n 1 protoc --go_out=plugins=grpc:$GOPATH/src
