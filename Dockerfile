# The image is based off of the rocker base image, which you can learn about here:
# https://rocker-project.org/
# The image is based off of ubuntu, but then runs a few scripts to install R and R shiny
FROM  ubuntu:jammy

COPY rocker/rocker/scripts /rocker_scripts

ENV R_VERSION=4.2.2
ENV R_HOME=/usr/local/lib/R
ENV TZ=Etc/UTC
ENV CRAN=https://packagemanager.posit.co/cran/__linux__/jammy/latest
ENV LANG=en_US.UTF-8

RUN /rocker/rocker/scripts/install_R_source.sh
RUN /rocker/rocker/scripts/setup_R.sh
ENV S6_VERSION=v2.1.0.2
ENV SHINY_SERVER_VERSION=latest
ENV PANDOC_VERSION=default
RUN /rocker/rocker/scripts/install_shiny_server.sh


# I added this label, though it doesn't do anything
LABEL name=Heat_CVD_UHI_Dashboard

# I reset the ubuntu package mirror to the Oregon State open source lab, because at some point while I was working on this
# The official ubuntu package mirror went offline, but this can probably be removed
RUN sed -i -e 's/http:\/\/archive\.ubuntu\.com\/ubuntu\//http:\/\/ubuntu\.osuosl\.org\/ubuntu/' /etc/apt/sources.list

# This part is the part that installs the system packages, usually needed for use in compiling some R pacakage.
# I just added packages to this list as I got errors
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    default-jdk \
    r-cran-rjava \
    r-base-dev dh-r automake \
    libharfbuzz-dev  libfribidi-dev \
    libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev \
    libgdal-dev \
    libudunits2-dev \
    cmake \
    && apt-get clean

# This sets the main path in the docker image to /app, which is a standard practice.
WORKDIR /app

# This is part copies in the renv dependency list
# The reason this is copied in seperately is for caching. Docker if it sees the dependencies haven't changed doesn't have to spend
# the time re-compiling everything
COPY renv.lock renv.lock
RUN mkdir -p renv
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.dcf renv/settings.dcf
RUN Rscript -e 'install.packages("renv")'
RUN Rscript -e 'renv::restore()'

# This part copies in the rest of the project
COPY . /app

# This sets what is run when the docker image is run
CMD ["Rscript", "run.R"]
