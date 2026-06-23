# Build environment for the rebar3_efene plugin.
# Stage 1 baseline: an Erlang/OTP close to the last commit (2018-05), so the
# plugin and its hex deps build with the fewest possible changes. Later stages
# bump OTP_VERSION one major at a time.
#
# Note: rebar3 contemporary with the commit (3.6.x) can no longer resolve deps
# from hex.pm because the package registry format it used was retired, so we
# use the rebar3 bundled in the official erlang image (still period-appropriate
# enough and able to talk to current hex).
ARG OTP_VERSION=21
FROM erlang:${OTP_VERSION}

RUN rebar3 --version

WORKDIR /app
COPY . .

# Compile the plugin and its dependency tree.
RUN rebar3 compile
