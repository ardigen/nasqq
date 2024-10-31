FROM rocker/r-base:4.2.2

LABEL maintainer="USER <lukasz.pruss@ardigen.com>"
LABEL org.opencontainers.image.source=https://github.com/ardigen/nasqq
LABEL org.opencontainers.image.description="r_utils"

RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    libbz2-dev \
    libharfbuzz-dev \
    libpng-dev \
    libtiff5-dev \ 
    libjpeg-dev \
    libfribidi-dev \
    libfreetype-dev \
    libfontconfig1-dev \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    cmake \
    libxml2-dev \
    libpq-dev \
    libnetcdf-dev \
    libgsl-dev \
    procps \
    elinks && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN Rscript -e 'install.packages("remotes"); \
                remotes::install_version("renv", "1.0.3")'

RUN mkdir /renvtmp
COPY renv.lock /renvtmp/
RUN cd /renvtmp && R -e 'options(timeout=50000); renv::restore(library = .libPaths()[1])'
RUN rm -rf /renvtmp
                      
COPY r_utils /r_utils
RUN R CMD build /r_utils
RUN R CMD INSTALL /rutils_1.0.tar.gz
