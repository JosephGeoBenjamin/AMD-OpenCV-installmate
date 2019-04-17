# This dockerfile is meant to be personalized, and serves as a template and demonstration.
# Modify it directly, but it is recommended to copy this dockerfile into a new build context (directory),
# modify to taste and modify docker-compose.yml.template to build and run it.

# It is recommended to control docker containers through 'docker-compose' https://docs.docker.com/compose/
# Docker compose depends on a .yml file to control container sets
# rocm-setup.sh can generate a useful docker-compose .yml file
# `docker-compose run --rm <rocm-terminal>`

# If it is desired to run the container manually through the docker command-line, the following is an example
# 'docker run -it --rm -v [host/directory]:[container/directory]:ro <user-name>/<project-name>'.

FROM ubuntu:16.04

# Initialize the image
# Modify to pre-install dev tools and ROCm packages
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl && \
  curl -sL http://repo.radeon.com/rocm/apt/debian/rocm.gpg.key | apt-key add - && \
  sh -c 'echo deb [arch=amd64] http://repo.radeon.com/rocm/apt/debian/ xenial main > /etc/apt/sources.list.d/rocm.list' && \
  apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  sudo \
  libelf1 \
  libnuma-dev \
  build-essential \
  git \
  vim-nox \
  byobu \
  cmake-curses-gui

# Rocm Libraries
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    rocm-dev \
    rocm-libs \
    && apt-get -f install

#OpenCV dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install \
    checkinstall cmake pkg-config yasm gfortran libjpeg8-dev libjasper-dev libpng12-dev libtiff5-dev libtiff-dev \
    libavcodec-dev libavformat-dev libswscale-dev libdc1394-22-dev libxine2-dev libv4l-dev && \
    cd /usr/include/linux && \
    ln -s -f ../libv4l1-videodev.h videodev.h && \
    cd $cwd && \
    apt-get update && DEBIAN_FRONTEND=noninteractive \
    apt-get -y install --no-install-recommends libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev \
    libgtk2.0-dev libtbb-dev qt5-default \
    libatlas-base-dev \
    libfaac-dev libmp3lame-dev libtheora-dev \
    libvorbis-dev libxvidcore-dev \
    libopencore-amrnb-dev libopencore-amrwb-dev \
    libavresample-dev \
    x264 v4l-utils \
    libprotobuf-dev protobuf-compiler \
    libgoogle-glog-dev libgflags-dev \
    libgphoto2-dev libeigen3-dev libhdf5-dev

RUN DEBIAN_FRONTEND=noninteractive apt-get clean

# Grant members of 'sudo' group passwordless privileges
# Comment out to require sudo
###COPY sudo-nopasswd /etc/sudoers.d/sudo-nopasswd
RUN echo "%sudo   ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/sudo-nopasswd
# This is meant to be used as an interactive developer container
# Create user rocm-user as member of sudo group
# Append /opt/rocm/bin to the system PATH variable
RUN useradd --create-home -G sudo --shell /bin/bash rocm-user
#    sed --in-place=.rocm-backup 's|^\(PATH=.*\)"$|\1:/opt/rocm/bin"|' /etc/environment


USER rocm-user
WORKDIR /home/rocm-user
ENV PATH "${PATH}:/opt/rocm/bin"

#other ROCM libs
ENV HIP_PLATFORM "hcc"
RUN mkdir -p rocm-lib-install

RUN cd ~/rocm-lib-install && \
    git clone https://github.com/JosephGeoBenjamin/HIP-forOpenCV.git && \
    cd ./HIP-forOpenCV && mkdir -p build && cd build && cmake ../ && make -j12 && sudo make install && \
    cd ~

RUN cd ~/rocm-lib-install && \
    git clone --recursive https://github.com/ROCmSoftwarePlatform/Thrust.git && \
    sudo cp -r ./Thrust/thrust /opt/rocm/include && \
    cd ~

#OpenCV repos
RUN git clone https://github.com/JosephGeoBenjamin/opencv-hip.git
RUN git clone https://github.com/JosephGeoBenjamin/opencv_contrib-hip.git
#RUN git clone https://github.com/opencv/opencv_extra.git
ENV OPENCV_TEST_DATA_PATH "/home/rocm-user/opencv_extra/testdata/"
ENV LD_LIBRARY_PATH "/home/rocm-user/opencv-hip/build/lib:LD_LIBRARY_PATH"

# The following are optional enhancements for the command-line experience
# Uncomment the following to install a pre-configured vim environment based on http://vim.spf13.com/
# 1.  Sets up an enhanced command line dev environment within VIM
# 2.  Aliases GDB to enable TUI mode by default
#RUN curl -sL https://j.mp/spf13-vim3 | bash && \
#    echo "alias gdb='gdb --tui'\n" >> ~/.bashrc

# Default to a login shell

CMD ["bash", "-l"]
