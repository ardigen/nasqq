FROM rocker/r-base:4.2.2
LABEL maintainer="USER <lukasz.pruss@ardigen.com>"
LABEL org.opencontainers.image.source=https://github.com/ardigen/nasqq
LABEL org.opencontainers.image.description="r_utils"

RUN apt-get update && apt-get install -y --no-install-recommends \
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
                packages <- list(BiocManager = "1.30.22", devtools = "2.4.5", dplyr = "1.1.4", roxygen2 = "7.3.1", ggplot2 = "3.4.4", DT = "0.19", visNetwork = "2.1.2", igraph = "1.5.1", svglite = "2.1.2", optparse = "1.7.4", testthat = "3.2.1"); \
                lapply(names(packages), function(pkg) {remotes::install_version(pkg, version = packages[[pkg]], dependencies = TRUE, upgrade="never")})' && \
    Rscript -e 'BiocManager::install(pkgs=c("PepsNMR", "ASICS", "FELLA"), version="3.16", ask = FALSE)'

COPY r_utils /r_utils
RUN R CMD build /r_utils
RUN R CMD INSTALL rutils_1.0.tar.gz

