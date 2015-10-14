#!/bin/bash

# Make the build dir
mkdir -p /build/bin

# Get version variables
source /version.sh

## ETCD ##

# Download a gzipped archive and extract, much faster
curl -sSL -k https://github.com/coreos/etcd/archive/$ETCD_VERSION.tar.gz | tar -C /build -xz
mv /build/etcd* /build/etcd

cd /build/etcd

# Apply some 32-bit patches
curl https://raw.githubusercontent.com/mkaczanowski/docker-archlinux-arm/master/archlinux-etcd/patches/raft.go.patch > raft.go.patch
curl https://raw.githubusercontent.com/mkaczanowski/docker-archlinux-arm/master/archlinux-etcd/patches/server.go.patch > server.go.patch
curl https://raw.githubusercontent.com/mkaczanowski/docker-archlinux-arm/master/archlinux-etcd/patches/watcher_hub.go.patch > watcher_hub.go.patch
patch etcdserver/raft.go < raft.go.patch
patch etcdserver/server.go < server.go.patch
patch store/watcher_hub.go < watcher_hub.go.patch

# Build etcd
./build

# Copy over the binaries
cp bin/* /build/bin


## FLANNEL ##

# Download a gzipped archive and extract, much faster
curl -sSL -k https://github.com/coreos/flannel/archive/$FLANNEL_VERSION.tar.gz | tar -C /build -xz
mv /build/flannel* /build/flannel

cd /build/flannel

# And build
./build

# Copy over the binaries
cp bin/* /build/bin


### KUBERNETES ###

# Download a gzipped archive and extract, much faster
curl -sSL -k https://github.com/kubernetes/kubernetes/archive/$K8S_VERSION.tar.gz | tar -C /build -xz
mv /build/kubernetes* /build/kubernetes

cd /build/kubernetes


## PATCHES FOR K8S BUILDING

# Do not build these packages
# Now it should be much faster
TOREMOVE=(
	"cmd/kube-proxy"
	"cmd/kube-apiserver"
	"cmd/kube-controller-manager"
	"cmd/kubelet"
	#"cmd/linkcheck"
	"cmd/kubernetes"
	"plugin/cmd/kube-scheduler"

	" kube-apiserver"
	" kube-controller-manager"
	" kube-scheduler"

	#"cmd/integration"
	#"cmd/gendocs"
    #"cmd/genman"
    #"cmd/mungedocs"
    #"cmd/genbashcomp"
    #"cmd/genconversion"
    #"cmd/gendeepcopy"
    #"examples/k8petstore/web-server"
    #"cmd/genswaggertypedocs"
    #"github.com/onsi/ginkgo/ginkgo"
    #"test/e2e/e2e.test"
)
  
# Loop each and remove them
for STR in "${TOREMOVE[@]}"; do
	sed -e "s@ $STR@@" -i hack/lib/golang.sh
done


# Do not build test targets
sed -e 's/ "\${KUBE_TEST_TARGETS\[@\]}" / /' -i hack/lib/golang.sh

# Build kubectl statically, instead of hyperkube
sed -e "s@ hyperkube@ kubectl@" -i hack/lib/golang.sh


# Build kubernetes binaries
./hack/build-go.sh

# Copy over the binaries
cp _output/local/bin/linux/arm/* /build/bin

## PAUSE ##

cd build/pause

# Build the binary
./prepare.sh

# Copy over the binaries
cp pause /build/bin
cp /gopath/bin/goupx /build/bin

## KUBE2SKY ##

cd /build/kubernetes/cluster/addons/dns/kube2sky

# Required for building this
# It makes the current kubernetes repo location accessible from the default gopath location
mkdir -p /gopath/src/github.com/GoogleCloudPlatform /gopath/src/k8s.io/
ln -s /build/kubernetes /gopath/src/github.com/GoogleCloudPlatform/kubernetes
ln -s /build/kubernetes /gopath/src/k8s.io/kubernetes

# Build for arm
sed -e "s@GOARCH=amd64@GOARCH=arm@" -i Makefile

# Build the binary
make kube2sky

# Include in build result
cp kube2sky /build/bin


## SKYDNS ##

# Compile the binary statically, requires mercurial
#go get github.com/skynetservices/skydns
CGO_ENABLED=0 go get -a -installsuffix cgo --ldflags '-w' github.com/skynetservices/skydns

# And copy over it
cp /gopath/bin/skydns /build/bin


## EXECHEALTHZ ##

cd /build/kubernetes/contrib/exec-healthz

# Build the binary
make server

# Copy over the binary
cp exechealthz /build/bin


## IMAGE REGISTRY ## 

REGISTRY_DIR=$GOPATH/src/github.com/docker/distribution

# Make the dir
mkdir -p $REGISTRY_DIR

# Download source
curl -sSL https://github.com/docker/distribution/archive/$REGISTRY_VERSION.tar.gz | tar -xz -C $REGISTRY_DIR --strip-components=1

# And compile. This gopath hack may also be resolved by using godep
GOPATH=$REGISTRY_DIR/Godeps/_workspace:$GOPATH make -C $REGISTRY_DIR $REGISTRY_DIR/bin/registry 

# Copy the binary
cp $REGISTRY_DIR/bin/registry /build/bin