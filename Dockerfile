FROM ruby:2.3

WORKDIR /opt/pusher-fake

ADD Gemfile /opt/pusher-fake/Gemfile
ADD Gemfile.lock /opt/pusher-fake/Gemfile.lock
ADD pusher-fake.gemspec /opt/pusher-fake/pusher-fake.gemspec

RUN bundle install --deployment --without development test

ADD . /opt/pusher-fake

EXPOSE 10080 10081

ENTRYPOINT ["/usr/local/bundle/bin/pusher-fake",  "--web-port", "10080", "--socket-port", "10081"]
