# Build environment for the rebar3_efene plugin.
#
#   docker build --build-arg OTP_VERSION=29 -t r3efene:otp29 .
#
# OTP_VERSION is bumped one major at a time; each value is a baseline that
# builds with no warnings or errors. efene is fetched from hex (>= 0.99.3, the
# modernized release); the rebar3_efene_compile/ct/shell sub-plugins are
# vendored under src/vendor/.
ARG OTP_VERSION=29
FROM erlang:${OTP_VERSION}

WORKDIR /app
COPY . .

# Compile the plugin and its efene dependency.
RUN rebar3 compile
