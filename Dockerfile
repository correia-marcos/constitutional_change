################################################################################
# STAGE 1: Builder — renv restore via Posit Package Manager (binary CRAN)
################################################################################
FROM rocker/r-ver:4.4.2 AS builder

LABEL org.opencontainers.image.source="https://github.com/your-org/your-repo" \
      org.opencontainers.image.version="v1.0.0" \
      maintainer="Your Name <you@example.com>"

# System libs commonly required by R packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates build-essential cmake pkg-config \
    libxml2-dev libssl-dev libcurl4-openssl-dev libgit2-dev \
    libgdal-dev libgeos-dev libproj-dev libudunits2-dev \
    libpng-dev libfreetype6-dev libfontconfig1-dev libharfbuzz-dev libfribidi-dev \
 && rm -rf /var/lib/apt/lists/*

# Use Posit Package Manager (binary CRAN) + reliable UA
ENV RENV_CONFIG_PPM_ENABLED=TRUE \
    RENV_CONFIG_PPM_URL="https://packagemanager.posit.co/cran/__linux__/bookworm/latest" \
    RENV_CONFIG_REPOS_OVERRIDE="https://packagemanager.posit.co/cran/__linux__/bookworm/latest" \
    RENV_CONFIG_SANDBOX_ENABLED=FALSE \
    RENV_CONFIG_CACHE_SYMLINKS=FALSE

RUN mkdir -p /usr/local/lib/R/etc && printf '%s\n' \
  'options(repos=c(CRAN="https://packagemanager.posit.co/cran/__linux__/bookworm/latest"))' \
  'options(HTTPUserAgent=sprintf("R/%s R (%s)", getRversion(), paste(R.version[["platform"]], R.version[["arch"]], R.version[["os"]])) )' \
  >> /usr/local/lib/R/etc/Rprofile.site

WORKDIR /paper

# Minimal renv bootstrap (cache-friendly layers)
COPY renv.lock renv.lock
COPY renv/activate.R renv/activate.R
COPY .Rprofile .Rprofile
# (If you have renv/settings.dcf, include it too)
# COPY renv/settings.dcf renv/settings.dcf

# Use global, in-image renv library/cache
ENV RENV_PATHS_LIBRARY=/opt/renv/library \
    RENV_PATHS_CACHE=/opt/renv/cache
RUN mkdir -p /opt/renv/library /opt/renv/cache

RUN R -q -e "install.packages('renv'); \
             renv::consent(provided=TRUE); \
             renv::activate('.'); \
             renv::settings$use.cache(TRUE); \
             renv::restore(lockfile='renv.lock', prompt=FALSE)"

################################################################################
# STAGE 2: Runtime — RStudio + Python venv + JupyterLab (Python kernel only)
################################################################################
FROM rocker/rstudio:4.4.2 AS final

LABEL org.opencontainers.image.source="https://github.com/your-org/your-repo" \
      org.opencontainers.image.version="v1.0.0" \
      maintainer="Your Name <you@example.com>"

ENV DEBIAN_FRONTEND=noninteractive LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 TZ=America/Sao_Paulo

# Runtime libs + Python 3.12 + venv
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git locales tzdata \
    python3.12 python3.12-venv python3.12-dev \
    libxml2 libssl3 libcurl4 libgit2-1.6 \
    libgdal32 libgeos-c1v5 libproj25 libudunits2-0 \
    libpng16-16 libfreetype6 libfontconfig1 libharfbuzz0b libfribidi0 \
    fonts-dejavu fonts-liberation \
 && sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen \
 && rm -rf /var/lib/apt/lists/*

# Keep PPM for any interactive R installs
RUN mkdir -p /usr/local/lib/R/etc && printf '%s\n' \
  'options(repos=c(CRAN="https://packagemanager.posit.co/cran/__linux__/bookworm/latest"))' \
  'options(HTTPUserAgent=sprintf("R/%s R (%s)", getRversion(), paste(R.version[["platform"]], R.version[["arch"]], R.version[["os"]])) )' \
  >> /usr/local/lib/R/etc/Rprofile.site

# Python virtual env
ENV VIRTUAL_ENV=/opt/venv
RUN python3.12 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN pip install --upgrade pip wheel

WORKDIR /paper

# Optional: Python deps (add your NLP/ML stacks in requirements.txt)
COPY requirements.txt /paper/requirements.txt
RUN if [ -s requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi

# Install JupyterLab + Python kernel only (NO IRkernel here)
RUN pip install --no-cache-dir jupyterlab ipykernel \
 && python -m ipykernel install --sys-prefix

# renv paths + copy pre-restored library from builder
ENV RENV_PATHS_LIBRARY=/opt/renv/library \
    RENV_PATHS_CACHE=/opt/renv/cache \
    RENV_CONFIG_SANDBOX_ENABLED=FALSE \
    RENV_CONFIG_CACHE_SYMLINKS=FALSE
COPY --from=builder /opt/renv/library /opt/renv/library

# Bring in project files last (code changes won’t rebuild deps)
COPY . /paper

# RStudio prefs (optional)
COPY rstudio-prefs.json /home/rstudio/.config/rstudio/rstudio-prefs.json
RUN chown -R rstudio:rstudio /home/rstudio/.config/rstudio

# Entrypoint (controls rserver/jupyter/batch)
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8787 8888
HEALTHCHECK --interval=30s --timeout=5s --retries=5 CMD curl -fsS http://localhost:8787/ || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["rserver"]