mkidir Downloads
cd Downloads
apt-get install wget
wget https://github.com/jemalloc/jemalloc/releases/download/5.2.1/jemalloc-5.2.1.tar.bz2
tar xvjf jemalloc-5.2.1.tar.bz2
cd jemalloc-5.2.1
./configure
make
make install
cd ..
cd ..