FROM ruby:2.3
MAINTAINER Dave Long <dlong@cagedata.com>

RUN apt-get update \
  && apt-get install -yqq --no-install-recommends nodejs \
  && rm -rf /var/lib/apt/lists/*

ENV TS_NODE /usr/bin/nodejs

WORKDIR /app
COPY Gemfile* /app/
RUN bundle install
COPY . /app/

EXPOSE 3030
VOLUME ["/app"]
CMD ["bundle", "exec", "dashing", "start"]
