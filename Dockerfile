# Build environment for the rebar3_efene plugin.
#
# IMPORTANT: build with the PARENT efene repo as the context, so the fixed,
# self-contained efene can be supplied as a rebar3 _checkouts override:
#
#   docker build -f rebar3_efene/Dockerfile \
#                --build-arg OTP_VERSION=29 -t r3efene:otp29 .
#
# (run from /home/mariano/src/efene). OTP_VERSION is bumped one major at a time;
# each value is a baseline that builds with no warnings or errors.
ARG OTP_VERSION=23
FROM erlang:${OTP_VERSION}

WORKDIR /app

# The fixed efene (vendors aleppo + ast_walk, no external deps) as a local
# checkout override, so no unmaintained packages are fetched from hex.
COPY src           _checkouts/efene/src
COPY include       _checkouts/efene/include
COPY rebar.config  _checkouts/efene/rebar.config

# The plugin itself (sub-plugins are vendored under src/vendor/).
COPY rebar3_efene/src          src
COPY rebar3_efene/rebar.config rebar.config

# Compile the plugin against the checked-out efene.
RUN rebar3 compile
