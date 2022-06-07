# [Choice] Debian version: bullseye, buster, stretch
ARG VARIANT=0.202.6-buster
FROM mcr.microsoft.com/vscode/devcontainers/base:${VARIANT}
# FROM registry.gitlab.com/fortyau/client-care-group/sijome-backend/dev

ENV LANG C.UTF-8

RUN wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb && sudo dpkg -i erlang-solutions_2.0_all.deb
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -

ENV NPM_VERSION=8.10.0
ENV NODE_VERSION=16.15.0-deb-1nodesource1
ENV HTMLBEAUTIFIER_VERSION=1.3.1
ENV ELIXIR_VERSION=1.13.0-1
ENV ERLANG_VERSION=1:24.3.3-1

# ** [Optional] Uncomment this section to install additional packages. **
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get upgrade -qq -y \
    && apt-get -qq -y install --no-install-recommends \
    esl-erlang=${ERLANG_VERSION} \
    elixir=${ELIXIR_VERSION} \
    nodejs=${NODE_VERSION} \
    inotify-tools \
    make \
    gcc \
    build-essential \
    ruby

RUN gem install htmlbeautifier -v ${HTMLBEAUTIFIER_VERSION}

RUN npm i -g npm@${NPM_VERSION}

RUN mkdir -p /app

RUN chown -R vscode /app
RUN chown -R vscode /usr/lib/node_modules

USER vscode

WORKDIR /app

# # Install hex package manager
RUN mix local.hex --force && \
    mix local.rebar --force
