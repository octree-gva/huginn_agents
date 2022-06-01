ARG HUGINN_IMAGE=git.octree.ch:4567/o/huginn-lite/releases:latest
FROM $HUGINN_IMAGE as base

RUN apk --update --no-cache add \
    build-base \
    libstdc++ && \
    rm -rf /var/cache/apk/*

COPY ./huginn_harvest /home/huginn/gems/harvest
COPY ./huginn_mongodb /home/huginn/gems/mongodb
COPY ./huginn_notion /home/huginn/gems/notion
COPY ./huginn.yml /home/huginn/app/config/huginn.yml

RUN  bundle install

FROM $HUGINN_IMAGE

COPY --from=base /usr/local/bundle/ /usr/local/bundle/
COPY --from=base /home/huginn/gems /home/huginn/gems
COPY --from=base /home/huginn/app/Gemfile.lock /home/huginn/app/Gemfile.lock
COPY --from=base /home/huginn/app/config/huginn.yml /home/huginn/app/config/huginn.yml
