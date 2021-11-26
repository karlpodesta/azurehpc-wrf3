#!/bin/bash

sudo yum -y groupinstall "Development Tools"
sudo yum -y install epel-release htop python-pathlib screen clang python3 tcsh java perl-devel 

setenforce 0
# Disable SELinux
cat  << EOF > /etc/selinux/config
SELINUX=disabled
EOF

sudo yum -y install tmux scl file gcc gcc-gfortran gcc-c++ glibc.i686 libgcc.i686 libpng-devel jasper \
  jasper-devel hostname m4 make perl tar bash time wget which zlib zlib-devel \
  openssh-clients openssh-server net-tools fontconfig libgfortran libXext libXrender \
  ImageMagick sudo epel-release git help2man

mkdir -p /data/wrf3/Build_WRF
mkdir -p /data/wrf3/TESTS

cd /data/wrf3/Build_WRF
mkdir LIBRARIES
cd LIBRARIES

wget http://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/netcdf-4.1.3.tar.gz 
wget http://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-1.900.1.tar.gz 
wget http://prdownloads.sourceforge.net/libpng/libpng-1.6.37.tar.gz?download
wget http://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/zlib-1.2.7.tar.gz
wget https://github.com/westes/flex/archive/refs/tags/v2.6.4.tar.gz
wget https://support.hdfgroup.org/ftp/HDF/releases/HDF4.2.13/src/hdf-4.2.13.tar.gz
wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.4/src/hdf5-1.10.4.tar.gz
wget https://www.ijg.org/files/jpegsrc.v9d.tar.gz
mv libpng-1.6.37.tar.gz\?download libpng-1.6.37.tar.gz

####################### SETENV

ulimit -s unlimited

export OPENSSL=openssl
export YACC="yacc -d"
export J="-j 12"

export DIR=/data/wrf3/Build_WRF/LIBRARIES

# COMPILERS
export CC=gcc
export FC=gfortran
export SERIAL_FC=gfortran
export SERIAL_F77=gfortran
export SERIAL_CC=gcc
export SERIAL_CXX=g++
export MPI_FC=mpif90
export MPI_F77=mpif77
export MPI_CC=mpicc
export MPI_CXX=mpicxx

export PATH=$DIR/openmpi/bin:$PATH
export PATH=$DIR/netcdf/bin:$PATH
export NETCDF=$DIR/netcdf
export JASPERLIB=$DIR/jasper/lib
export JASPERINC=$DIR/jasper/include
export FLEX=$DIR/flex/bin/flex
export FLEX_LIB_DIR=$DIR/flex/lib
export HDF4=$DIR/hdf4
export HDF5=$DIR/hdf5
export OPENMPI=$DIR/openmpi
export LIBPNG=$DIR/libpng
export LIBPNGLIB=$DIR/libpng
export HDFEOS2=$DIR/hdfeos2
export NCARG=$DIR/ncl
export SZIP=$DIR/szip
export JPEG=$DIR/jpeg
export SQLITE3=$DIR/sqlite336
export GDAL=$DIR/gdal


# run-time linking   ${H5DIR}/lib
export LD_LIBRARY_PATH=${HDF5}/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${HDF4}/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${NETCDF}/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${JASPERLIB}:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${FLEX_LIB_DIR}:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${FLEX_LIB_DIR}:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${OPENMPI}/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${LIBPNG}/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${HDFEOS2}/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${SZIP}/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${SQLITE3}/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${GDAL}/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/lib64:$LD_LIBRARY_PATH

# LDOPE
export ANCPATH=/data/wrf3/Build_WRF/VPRM/ldope_32bit_i386_static_patched/ANCILLARY

# VPRMPreproc
export VPRM=/data/wrf3/Build_WRF/VPRM/VPRMpreproc_R99

# WRF
export WRFV3=/data/wrf3/Build_WRF/WRFV3
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
export WRF_CHEM=1
export WRF_KPP=1

################# EOF

#chmod +x /data/setenv.sh
#source /data/setenv.sh

module avail
module load gcc-9.2.0
module load mpi/openmpi
# zlib
cd /data/wrf3/Build_WRF/LIBRARIES
tar -zxvf zlib-1.2.7.tar.gz
cd /data/wrf3/Build_WRF/LIBRARIES/zlib-1.2.7
./configure --prefix=$DIR/zlib
make
make install
cd ..
# jpeg-9b
cd /data/wrf3/Build_WRF/LIBRARIES
tar zxvf jpegsrc.v9d.tar.gz
cd /data/wrf3/Build_WRF/LIBRARIES/jpeg-9d
./configure --prefix=$DIR/jpeg --disable-dependency-tracking
make
make install
cd ..
# netcdf
cd /data/wrf3/Build_WRF/LIBRARIES
tar zxvf netcdf-4.1.3.tar.gz
cd /data/wrf3/Build_WRF/LIBRARIES/netcdf-4.1.3
export LDFLAGS="-L$DIR/zlib/lib -L$DIR/jpeg/lib"
export CPFLAGS="-I$DIR/zlib/include -I$DIR/jpeg/include"
./configure --prefix=$DIR/netcdf --disable-dap --disable-netcdf-4    
# ./configure --prefix=$DIR/netcdf --disable-dap --disable-netcdf-4 --disable-shared  # Check if this should be with shared libraries
make
make install
# hdf4 (Build netcdf first!!! and enable shared-libraries - Is Needed by OBSGRID later)
cd /data/wrf3/Build_WRF/LIBRARIES
tar zxvf hdf-4.2.13.tar.gz
cd /data/wrf3/Build_WRF/LIBRARIES/hdf-4.2.13
# ./configure --prefix=$DIR/hdf4 --with-zlib=$DIR/zlib --enable-fortran --with-jpeg=$DIR/jpeg   # --> Use this with gcc-4.8.5 (DOES NOT WORK WITH OBSGRID)
# ./configure --prefix=$DIR/hdf4 --with-zlib=$DIR/zlib --enable-fortran --with-jpeg=$DIR/jpeg   --with-gnu-ld    # --> Use this with gcc-9.2.0 (DOES NOT WORK WITH OBSGRID)
./configure --prefix=$DIR/hdf4 --with-zlib=$DIR/zlib --disable-fortran --with-jpeg=$DIR/jpeg --enable-shared --with-gnu-ld    # --> Use this with gcc-9.2.0 (THIS ONE WORKS!)
make 
make install
cd ..
# hdf5
cd /data/wrf3/Build_WRF/LIBRARIES
tar zxvf hdf5-1.10.4.tar.gz
cd /data/wrf3/Build_WRF/LIBRARIES/hdf5-1.10.4 
./configure --prefix=$DIR/hdf5 --enable-hl --enable-fortran --enable-unsupported --enable-cxx  --with-zlib=$DIR/zlib --with-pic
make 
make install
cd ..
# libpng
cd /data/wrf3/Build_WRF/LIBRARIES
tar -zxvf libpng-1.6.37.tar.gz
cd /data/wrf3/Build_WRF/LIBRARIES/libpng-1.6.37
export LDFLAGS=-L$DIR/zlib/lib
export CPFLAGS=-I$DIR/zlib/include
./configure --prefix=$DIR/libpng
make
make install
cd ..
#JasPer
cd /data/wrf3/Build_WRF/LIBRARIES
tar -zxvf jasper-1.900.1.tar.gz
cd /data/wrf3/Build_WRF/LIBRARIES/jasper-1.900.1
./configure --prefix=$DIR/jasper
make
make install
cd ..
#Flex
sudo yum install -y help2man
cd /data/wrf3/Build_WRF/LIBRARIES
tar -zxvf v2.6.4.tar.gz
cd /data/wrf3/Build_WRF/LIBRARIES/flex-2.6.4
./autogen.sh
./configure --prefix=$DIR/flex
make
make install
cd ..
# H4toH5 (Just download the precompiled binaries for Linux )
cd /data/wrf3/Build_WRF/LIBRARIES
wget https://support.hdfgroup.org/ftp/HDF5/releases/tools/h4toh5/h4toh5-2.2.5/bin/h4h5tools-1.10.6-2.2.5-centos7_64.tar.gz
tar -zxvf h4h5tools-1.10.6-2.2.5-centos7_64.tar.gz
cd /data/wrf3/Build_WRF/LIBRARIES/hdf
./H4H5-2.2.5-Linux.sh --skip-license
cd HDF_Group/H4H5/2.2.5/bin
#./h4toh5convert -h

## BUILD WRF3
cd /data/wrf3/Build_WRF
wget https://github.com/wrf-model/WRF/archive/refs/tags/V3.3.1.tar.gz
tar xzvf V3.3.1.tar.gz
cd WRF-3.3.1
./clean -a
#./configure
# Choose 17 and 1
# sed `s/^DM_CC/DM_CC           =       mpicc -DMPI2_SUPPORT/`
# ./compile em_real >& compile.log &




