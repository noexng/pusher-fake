FROM ruby:2.3

WORKDIR /opt/pusher-fake

ADD Gemfile /opt/pusher-fake/Gemfile
ADD Gemfile.lock /opt/pusher-fake/Gemfile.lock
ADD pusher-fake.gemspec /opt/pusher-fake/pusher-fake.gemspec

RUN bundle install --deployment --without development test

ADD . /opt/pusher-fake

EXPOSE 80 81

CMD /usr/local/bundle/bin/pusher-fake --web-port 80 --socket-port 81 --app-id $PUSHER_APP_ID --key $PUSHER_KEY --secret $PUSHER_SECRET
