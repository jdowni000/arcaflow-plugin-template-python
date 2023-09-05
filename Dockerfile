# Package path for this plugin module relative to the repo root
ARG package=arcaflow_plugin_template_python

# STAGE 1 -- Build module dependencies and run tests
# The 'poetry' and 'coverage' modules are installed and verson-controlled in the
# quay.io/arcalot/arcaflow-plugin-baseimage-python-buildbase image to limit drift
FROM quay.io/centos/centos:stream8@sha256:7b6efe39fa1307fb7590ba8496876fadcbba04f11fddc0d29bdbffb89b50f538 as build
RUN dnf -y module install python39 && dnf -y install python39 python39-pip
ARG package

WORKDIR /app

COPY poetry.lock /app/
COPY pyproject.toml /app/

# Convert the dependencies from poetry to a static requirements.txt file
RUN python3.9 -m pip install poetry==1.4.2 \
 && python3.9 -m poetry config virtualenvs.create false \
 && python3.9 -m poetry install --without dev --no-root \
 && python3.9 -m poetry export -f requirements.txt --output requirements.txt --without-hashes

COPY ${package}/ /app/${package}
COPY tests /app/${package}/tests

ENV PYTHONPATH /app/${package}
WORKDIR /app/${package}

# Run tests and return coverage analysis
RUN pip3 install coverage
RUN python3.9 -m coverage run tests/test_${package}.py \
 && python3.9 -m coverage html -d /htmlcov --omit=/usr/local/*


# STAGE 2 -- Build final plugin image
FROM quay.io/centos/centos:stream8@sha256:7b6efe39fa1307fb7590ba8496876fadcbba04f11fddc0d29bdbffb89b50f538
RUN dnf -y module install python39 && dnf -y install python39 python39-pip
ARG package

WORKDIR /app

COPY --from=build /app/requirements.txt /app/
COPY --from=build /htmlcov /htmlcov/
COPY LICENSE /app/
COPY README.md /app/
COPY ${package}/ /app/${package}

# Install all plugin dependencies from the generated requirements.txt file
RUN python3.9 -m pip install -r requirements.txt

WORKDIR /app/${package}

ENTRYPOINT ["python3.9", "arcaflow_plugin_template_python.py"]
CMD []

LABEL org.opencontainers.image.source="https://github.com/arcalot/arcaflow-plugin-template-python"
LABEL org.opencontainers.image.licenses="Apache-2.0+GPL-2.0-only"
LABEL org.opencontainers.image.vendor="Arcalot project"
LABEL org.opencontainers.image.authors="Arcalot contributors"
LABEL org.opencontainers.image.title="Python Plugin Template"
LABEL io.github.arcalot.arcaflow.plugin.version="1"
