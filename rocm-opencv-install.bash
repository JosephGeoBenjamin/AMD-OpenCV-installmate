#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

WORKDIR=$(pwd)
echo "##--- OpenCV-hip Installer ---" >> ~/.bashrc

## Add Rocm-Keys
sudo apt-get update && sudo apt-get install -y --no-install-recommends curl && \
  curl -sL http://repo.radeon.com/rocm/apt/debian/rocm.gpg.key | apt-key add - && \
  sh -c 'echo deb [arch=amd64] http://repo.radeon.com/rocm/apt/debian/ xenial main > /etc/apt/sources.list.d/rocm.list'

## Rocm-dkms must be previously installed

## Basic Libraries
sudo apt-get update && sudo apt-get -y upgrade &&
  sudo apt-get install -y --no-install-recommends \
  libelf1 \
  libnuma-dev \
  build-essential \
  git \
  vim-nox \
  cmake-curses-gui \
  libboost-all-dev \
  rocm-dev

## OpenCV-dependencies
sudo apt -y remove x264 libx264-dev
sudo apt -y install build-essential checkinstall cmake pkg-config yasm
sudo apt -y install git gfortran
sudo apt -y install libjpeg8-dev libjasper-dev libpng12-dev
sudo apt -y install libtiff5-dev
sudo apt -y install libtiff-dev
sudo apt -y install libavcodec-dev libavformat-dev libswscale-dev libdc1394-22-dev
sudo apt -y install libxine2-dev libv4l-dev
cd /usr/include/linux
sudo ln -s -f ../libv4l1-videodev.h videodev.h
cd $cwd
sudo apt -y install libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev
sudo apt -y install libgtk2.0-dev libtbb-dev qt5-default
sudo apt -y install libatlas-base-dev
sudo apt -y install libfaac-dev libmp3lame-dev libtheora-dev
sudo apt -y install libvorbis-dev libxvidcore-dev
sudo apt -y install libopencore-amrnb-dev libopencore-amrwb-dev
sudo apt -y install libavresample-dev
sudo apt -y install x264 v4l-utils
sudo apt -y install libprotobuf-dev protobuf-compiler
sudo apt -y install libgoogle-glog-dev libgflags-dev
sudo apt -y install libgphoto2-dev libeigen3-dev libhdf5-dev doxygen
sudo apt-get update && sudo apt-get -y upgrade

## exports Hip libs
echo "export LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64:$LD_LIBRARY_PATH"  >> ~/.bashrc
echo "export PATH=/opt/rocm/bin/:$PATH" >> ~/.bashrc
source ~/.bashrc

## Rocm-Lib Apt installation
# sudo apt-get update && apt-get install -y \
#     rocm-dev \
#     rocm-libs \
#     && apt-get -f install

## ROCM-LIBS SOURCE installation
mkdir -p $WORKDIR/rocm-lib-install

### Tested commits For 2.2.0
HIP_COMMIT=59c54da4f01758581d087bba94e476e39eed7c14 # not used
ROCBLAS_COMMIT=2333ed495b84f763c39b71d1f70152d23556bebf
HIPBLAS_COMMIT=ad4fb4c61e14cc482581502f8f66e6941d98c312
ROCFFT_COMMIT=273c18b2abc1a3e1e4ea6283178254d2760d2997
ROCRAND_COMMIT=7278524ea37f449795fdafcd0bf5307f61f06ba9
ROCTHRUST_COMMIT=2f23ffb3932f303d910cad824b327c11893f0d68 #2.3 commit

###Modified hip for OpenCV
cd $WORKDIR/rocm-lib-install
git clone https://github.com/JosephGeoBenjamin/HIP-forOpenCV.git
cd ./HIP-forOpenCV && mkdir -p build && cd build && cmake ../ && make -j12 && sudo make install
cd $WORKDIR

cd $WORKDIR/rocm-lib-install
git clone https://github.com/ROCmSoftwarePlatform/rocBLAS.git
cd ./rocBLAS && git checkout $ROCBLAS_COMMIT && sudo ./install.sh -idc
cd $WORKDIR

cd $WORKDIR/rocm-lib-install
git clone https://github.com/ROCmSoftwarePlatform/rocRAND.git
cd ./rocRAND && git checkout $ROCRAND_COMMIT
mkdir -p build && cd build && cmake -DCMAKE_CXX_COMPILER=/opt/rocm/bin/hcc ../ && make -j12 && sudo make install
cd $WORKDIR

cd $WORKDIR/rocm-lib-install
git clone https://github.com/ROCmSoftwarePlatform/rocFFT.git
cd ./rocFFT && git checkout $ROCFFT_COMMIT && ./install.sh -id
cd $WORKDIR

cd $WORKDIR/rocm-lib-install
git clone https://github.com/ROCmSoftwarePlatform/hipBLAS.git
cd ./hipBLAS && git checkout $HIPBLAS_COMMIT && ./install.sh -id
cd $WORKDIR

cd $WORKDIR/rocm-lib-install
git clone --recursive https://github.com/ROCmSoftwarePlatform/Thrust.git
git checkout $ROCTHRUST_COMMIT
sudo cp -r ./Thrust/thrust /opt/rocm/include
cd $WORKDIR

## OpenCV repos clone
git clone https://github.com/JosephGeoBenjamin/opencv-hip.git
git clone https://github.com/JosephGeoBenjamin/opencv_contrib-hip.git
git clone https://github.com/opencv/opencv_extra.git

echo "OPENCV_TEST_DATA_PATH=$WORKDIR/opencv_extra/testdata/"  >> ~/.bashrc
echo "LD_LIBRARY_PATH=$WORKDIR/opencv-hip/build/lib:$LD_LIBRARY_PATH"  >> ~/.bashrc
source ~/.bashrc
echo "##--- OpenCV-hip end ---" >> ~/.bashrc

## Build OpenCV
cd $WORKDIR/opencv-hip && mkdir -p build && cd build && cmake \
        -DCMAKE_CXX_COMPILER=/opt/rocm/bin/hipcc \
        -DCV_DISABLE_OPTIMIZATION=ON  \
        -DCV_ENABLE_INTRINSICS=OFF \
        -DWITH_HIP=ON \
        -DBUILD_LIST=core,highgui,cudev,cudabgsegm,cudalegacy,cudaimgproc,cudaarithm,cudafilters,cudawarping,cudastereo,cudafeatures2d,cudaoptflow,cudaobjdetect,cudacodec,ts \
        -DOPENCV_EXTRA_MODULES_PATH=$WORKDIR/opencv_contrib-hip/modules \
        ../

make -j12 opencv_test_core
make -j12 opencv_test_cudev
make -j12 opencv_test_cudaimgproc
make -j12 opencv_test_cudaarithm
make -j12 opencv_test_cudalegacy
make -j12 opencv_test_cudawarping
make -j12 opencv_test_cudafilters
make -j12 opencv_test_cudabgsegm
make -j12 opencv_test_cudafeatures2d
make -j12 opencv_test_cudastereo
make -j12 opencv_test_cudaobjdetect
make -j12 opencv_test_cudacodec
#make -j12 opencv_test_cudaoptflow

cd $WORK_DIR
