FROM slapi/ruby:latest

MAINTAINER SLAPI Devs

ENV APP_HOME /api

RUN mkdir -p $APP_HOME && chmod 777 $APP_HOME

WORKDIR /api

COPY supervisord.conf /etc/supervisor.d/supervisord.conf

# Copy app into container
COPY . $APP_HOME

RUN apk update && apk add \
    supervisor &&\
    if [ -f Gemfile.lock ]; then rm -f Gemfile.lock; fi &&\
    gem install json \
    sinatra \
    sinatra-contrib \
    httparty &&\
    rm -rf /var/cache/apk/* &&\
    rm -rf /tmp/*

EXPOSE 4700

ENTRYPOINT ["supervisord", "-c", "/etc/supervisor.d/supervisord.conf", "-n"]
