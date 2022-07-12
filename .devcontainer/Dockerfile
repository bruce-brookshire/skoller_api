# [Choice] Debian version: bullseye, buster, stretch
ARG VARIANT=0.202.6-buster
FROM mcr.microsoft.com/vscode/devcontainers/base:${VARIANT}

ENV LANG C.UTF-8

RUN wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb && sudo dpkg -i erlang-solutions_2.0_all.deb

ENV ELIXIR_VERSION=1.13.0-1
ENV ERLANG_VERSION=1:25.0.2-1

# ** [Optional] Uncomment this section to install additional packages. **
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get upgrade -qq -y \
    && apt-get -qq -y install --no-install-recommends \
    esl-erlang=${ERLANG_VERSION} \
    elixir=${ELIXIR_VERSION} \
    inotify-tools \
    make \
    gcc \
    build-essential \
    ruby

ENV HTMLBEAUTIFIER_VERSION=1.3.1
RUN gem install htmlbeautifier -v ${HTMLBEAUTIFIER_VERSION}

RUN mkdir -p /app

RUN chown -R vscode /app

USER vscode

ENV NVM_VERSION=v0.39.1
ENV NPM_VERSION=8.12.2
ENV NODE_VERSION=18.2.0

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash && \
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    nvm install ${NODE_VERSION} && \
    npm i -g npm@${NPM_VERSION}

WORKDIR /app

# # Install hex package manager
RUN mix local.hex --force && \
    mix local.rebar --force
