FROM ruby:2.7.5-slim-buster

ENV BINDING 0.0.0.0

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libxml2-dev \
      libxslt1-dev \
      imagemagick \
      libmariadb-dev \
      libsqlite3-dev

VOLUME /srv/skeinlink
WORKDIR /srv/skeinlink

ADD Gemfile* /srv/skeinlink/
RUN bundle install -j4 --retry 3

CMD ["bundle", "exec", "rails", "server"]
