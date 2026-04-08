FROM ubuntu:18.04

# 1. Install System Dependencies & FSL
RUN apt-get -y update && apt-get -y install \
    python wget ca-certificates libglu1-mesa libgl1-mesa-glx \
    libsm6 libice6 libxt6 libpng16-16 libxrender1 libxcursor1 \
    libxinerama1 libfreetype6 libxft2 libxrandr2 libgtk2.0-0 \
    libpulse0 libasound2 libcaca0 libopenblas-base bzip2 dc bc \
    git gcc libpq-dev python3 python3-dev python3-pip python3-wheel \
    && rm -rf /var/lib/apt/lists/*

# Install FSL (This is required by the script)
RUN mkdir -p /INSTALLERS && wget -O /INSTALLERS/fslinstaller.py "https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py" \
    && python /INSTALLERS/fslinstaller.py -d /APPS/FSL -V 6.0.3

# 2. Setup Directories
RUN mkdir -p /APPS/ants/bin /CODE /MODEL /SUPPLY /INPUTS /OUTPUTS

# 3. COPY your extracted folders
# Make sure these folders are in the SAME directory as this Dockerfile on caudate
COPY ./ants_extracted /APPS/ants/bin
COPY ./code_extracted /CODE
COPY ./supply_extracted /SUPPLY

# 4. Install Python Packages
RUN pip3 install torch==0.4.1 tqdm nibabel==3.0.2 numpy==1.18.1

# 5. Env Vars (Crucial for the script to find ANTs and FSL)
ENV FSLDIR=/APPS/FSL
ENV ANTSPATH=/APPS/ants/bin/
ENV PATH=${FSLDIR}/bin:${ANTSPATH}:${PATH}
ENV FSLOUTPUTTYPE=NIFTI_GZ

WORKDIR /CODE
ENTRYPOINT ["/bin/bash", "tractSeg_simg.sh", "/INPUTS", "/OUTPUTS"]
