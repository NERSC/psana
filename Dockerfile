FROM centos:6
MAINTAINER "bkpoon" bkpoon@lbl.gov
ENV container docker

# TODO:
#   1) use environment variables
#   2) use WORKDIR instead of cd

# install base packages for psdm
# https://confluence.slac.stanford.edu/display/PSDM/System+packages+for+rhel6
# fix libmysqlclient.so symbolic link
RUN yum -y install alsa-lib atk compat-libf2c-34 fontconfig freetype gsl \
    libgfortran libgomp libjpeg libpng libpng-devel pango postgresql-libs \
    unixODBC libICE libSM libX11 libXext libXft libXinerama libXpm \
    libXrender libXtst libXxf86vm mesa-libGL mesa-libGLU gtk2 \
    xorg-x11-fonts-Type1 xorg-x11-fonts-base xorg-x11-fonts-100dpi \
    xorg-x11-fonts-truetype xorg-x11-fonts-75dpi xorg-x11-fonts-misc \
    tar xz which gcc gcc-c++ mysql libibverbs openssh-server openssh
#    ln -s /usr/lib64/mysql/libmysqlclient.so.16 \
#          /usr/lib64/mysql/libmysqlclient.so

# install psdm
# https://confluence.slac.stanford.edu/display/PSDM/Software+Distribution
#RUN mkdir -p /reg/g/psdm
ADD http://pswww.slac.stanford.edu/psdm-repo/dist_scripts/site-setup.sh \
    /reg/g/psdm/
RUN sh /reg/g/psdm/site-setup.sh /reg/g/psdm
ENV SIT_ROOT=/reg/g/psdm
ENV PATH=/reg/g/psdm/sw/dist/apt-rpm/rhel6-x86_64/bin:$PATH
ENV APT_CONFIG=/reg/g/psdm/sw/dist/apt-rpm/rhel6-x86_64/etc/apt/apt.conf
#RUN apt-get -y update; apt-get -y install \
#            psdm-release-ana-0.17.4-x86_64-rhel6-gcc44-opt &&\
#    ln -s /reg/g/psdm/sw/releases/ana-0.17.4 \
#          /reg/g/psdm/sw/releases/ana-current
RUN apt-get -y update; apt-get -y install \
            psdm-release-ana-0.19.0-x86_64-rhel6-gcc44-opt &&\
    ln -s /reg/g/psdm/sw/releases/ana-0.19.0 \
          /reg/g/psdm/sw/releases/ana-current

# use old HDF5 (1.8.6) for compatibility with cctbx.xfel
ADD https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8.6/bin/linux-x86_64/hdf5-1.8.6-linux-x86_64-shared.tar.gz .
#COPY ./hdf5-1.8.6-linux-x86_64-shared.tar.gz .
RUN tar -xf hdf5-1.8.6-linux-x86_64-shared.tar.gz &&\
    mkdir -p /reg/g/psdm/sw/external/hdf5/1.8.6 &&\
    mv hdf5-1.8.6-linux-x86_64-shared \
       /reg/g/psdm/sw/external/hdf5/1.8.6/x86_64-rhel6-gcc44-opt

# add cray mpi

# build myrelease
RUN cd /reg/g &&\
    source /reg/g/psdm/etc/ana_env.sh &&\
    newrel ana-0.19.0 myrelease &&\
    cd myrelease &&\
    source sit_setup.sh &&\
    newpkg my_ana_pkg

# copy cctbx.xfel from local tarball
RUN mkdir -p /reg/g/cctbx
COPY ./xfel.tar.xz /reg/g/cctbx/xfel.tar.xz
RUN cd /reg/g/cctbx &&\
    tar -Jxf ./xfel.tar.xz

# build cctbx.xfel
# make needs to be run multiple times to ensure complete build (bug)
ENV CPATH=/reg/g/psdm/sw/releases/ana-0.19.0/arch/x86_64-rhel6-gcc44-opt/geninc
#:/reg/g/psdm/sw/releases/ana-0.19.0/arch/x86_64-rhel6-gcc44-opt/geninc/hdf5
ENV LD_LIBRARY_PATH=/reg/g/psdm/sw/releases/ana-0.19.0/arch/x86_64-rhel6-gcc44-opt/lib
RUN source /reg/g/psdm/etc/ana_env.sh &&\
    cd /reg/g/myrelease &&\
    sit_setup.sh &&\
    cd /reg/g/cctbx &&\
    python ./modules/cctbx_project/libtbx/auto_build/bootstrap.py build \
    --builder=dials --with-python=`which python` --nproc=32 &&\
    cd build &&\
    make -j 32 &&\
    make -j 32

# finish building myrelease
RUN source /reg/g/psdm/etc/ana_env.sh &&\
    cd /reg/g/myrelease &&\
    source /reg/g/psdm/bin/sit_setup.sh &&\
    source /reg/g/cctbx/build/setpaths.sh &&\
    cd my_ana_pkg &&\
    ln -s /reg/g/cctbx/modules/cctbx_project/xfel/cxi/cspad_ana src &&\
    cd .. &&\
    scons

# recreate /reg/d directories for data
RUN mkdir -p /reg/d/psdm/cxi &&\
    mkdir -p /reg/d/psdm/CXI
