FROM ubuntu:18.04

# 1. Install System Dependencies
RUN apt-get -y update && apt-get -y install \
    wget ca-certificates libglu1-mesa libgl1-mesa-glx \
    libsm6 libice6 libxt6 libpng16-16 libxrender1 libxcursor1 \
    libxinerama1 libfreetype6 libxft2 libxrandr2 libgtk2.0-0 \
    libpulse0 libasound2 libcaca0 libopenblas-base bzip2 dc bc \
    git gcc g++ make libpq-dev \
    libssl-dev zlib1g-dev \
    python python2.7 python3 python3-dev python3-pip python3-wheel \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /apps /INSTALLERS

# ── CMake (ANTs requires >= 3.20, apt version is too old) ─────────────────────
RUN cd /INSTALLERS && \
    wget https://github.com/Kitware/CMake/releases/download/v3.23.0-rc2/cmake-3.23.0-rc2.tar.gz && \
    tar -xf cmake-3.23.0-rc2.tar.gz && \
    cd cmake-3.23.0-rc2 && \
    ./bootstrap && \
    make -j$(nproc) && \
    make install && \
    rm -rf /INSTALLERS/cmake-3.23.0-rc2 /INSTALLERS/cmake-3.23.0-rc2.tar.gz

# ── FSL ───────────────────────────────────────────────────────────────────────
RUN wget -O /INSTALLERS/fslinstaller.py \
        "https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py" && \
    python2 /INSTALLERS/fslinstaller.py -d /apps/fsl -V 6.0.6 && \
    rm /INSTALLERS/fslinstaller.py

# 2. Setup Directories
RUN mkdir -p /apps/ants/bin /CODE /MODEL /SUPPLY /INPUTS /OUTPUTS

# ── ANTs ──────────────────────────────────────────────────────────────────────
RUN cd /INSTALLERS && \
    git clone https://github.com/ANTsX/ANTs.git ants_src && \
    cd ants_src && \
    git checkout efa80e3f582d78733724c29847b18f3311a66b54 && \
    touch README.txt && \
    mkdir -p /INSTALLERS/ants_build && \
    cd /INSTALLERS/ants_build && \
    cmake /INSTALLERS/ants_src -DCMAKE_INSTALL_PREFIX=/apps/ants && \
    make -j$(nproc) && \
    cd ANTS-build && \
    make install && \
    rm -rf /INSTALLERS/ants_src /INSTALLERS/ants_build

# 3. Copy Code and Supply
COPY ./code_extracted /CODE
COPY ./supply_extracted /SUPPLY

# 4. Install Python Packages
RUN /apps/fsl/bin/pip3 install --force-reinstall torch==2.2.0 tqdm nibabel==5.2.0 numpy==1.23.5

# 5. Env Vars
ENV FSLDIR=/apps/fsl
ENV ANTSPATH=/apps/ants/bin/
ENV PATH=${FSLDIR}/bin:${ANTSPATH}:${PATH}
ENV FSLOUTPUTTYPE=NIFTI_GZ

WORKDIR /CODE
ENTRYPOINT ["/bin/bash", "tractSeg_simg.sh"]
