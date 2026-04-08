# Use the same base image
FROM ubuntu:18.04

# Use non-interactive mode for apt to prevent hanging during build
ENV DEBIAN_FRONTEND=noninteractive

# 1. Setup Directories (%post equivalent)
RUN mkdir -p /APPS/ants/bin /CODE /MODEL /SUPPLY /INSTALLERS /INPUTS /OUTPUTS

# 2. Copy Files (%files equivalent)
# Note: These source paths must be relative to your "build context" (the folder where the Dockerfile is)
COPY ./ants/bin /APPS/ants/bin
COPY ./code /CODE
COPY ./model /MODEL
COPY ./supply /SUPPLY

# 3. Install Dependencies and FSL (%post equivalent)
RUN apt-get -y update && apt-get -y install \
    python \
    wget \
    ca-certificates \
    libglu1-mesa \
    libgl1-mesa-glx \
    libsm6 \
    libice6 \
    libxt6 \
    libpng16-16 \
    libxrender1 \
    libxcursor1 \
    libxinerama1 \
    libfreetype6 \
    libxft2 \
    libxrandr2 \
    libgtk2.0-0 \
    libpulse0 \
    libasound2 \
    libcaca0 \
    libopenblas-base \
    bzip2 \
    dc \
    bc \
    git \
    gcc \
    libpq-dev \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    python3-wheel \
    && rm -rf /var/lib/apt/lists/*

# Install FSL
WORKDIR /INSTALLERS
RUN wget -O fslinstaller.py "https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py" && \
    python fslinstaller.py -d /APPS/FSL -V 6.0.3

# Install Python packages
RUN pip3 install --no-cache-dir \
    torch==0.4.1 \
    tqdm \
    nibabel==3.0.2 \
    numpy==1.18.1

# 4. Set Permissions
RUN chmod 755 /INPUTS /SUPPLY /APPS /CODE && \
    chmod 775 /OUTPUTS

# 5. Environment Variables (%environment equivalent)
ENV FSLDIR=/APPS/FSL
ENV ANTSPATH=/APPS/ants/bin/
ENV PATH=${FSLDIR}/bin:${ANTSPATH}:${PATH}

# Source FSL config (Docker doesn't source files easily, so we set the env vars manually)
# This mimics what . ${FSLDIR}/etc/fslconf/fsl.sh does
ENV FSLOUTPUTTYPE=NIFTI_GZ

# 6. Runscript (%runscript equivalent)
WORKDIR /CODE
ENTRYPOINT ["/bin/bash", "tractSeg_simg.sh", "/INPUTS", "/OUTPUTS"]
