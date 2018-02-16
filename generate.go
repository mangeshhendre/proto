package main

import "fmt"

// Base models
//go:generate protoc --go_out=$GOPATH/src std/cache_v1.proto

// System specific models.
//go:generate protoc --go_out=$GOPATH/src std/media/media_v1.proto

// Services
//go:generate protoc --go_out=plugins=grpc:$GOPATH/src services/math/math_v1.proto

func main() {
	fmt.Println("This is not a real program, just a program used to generate code.")
}
