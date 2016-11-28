FROM ruby:2.3

RUN apt-get update -qq && \
    apt-get install -qq -y supervisor &&\
    apt-get autoremove -y && \
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Setup App Environment and User
ENV APP_HOME /slapi

RUN mkdir -p $APP_HOME

ADD supervisord.conf /etc/supervisor/conf.d/
ADD . $APP_HOME

RUN adduser slapi --disabled-password --gecos "" && \
    echo "slapi            ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers &&\
    chown -R slapi:slapi $APP_HOME && \
    chmod -R 774 $APP_HOME &&\
    chmod -R 777 /etc/supervisor &&\
    chown -R root:slapi /usr/local/lib/ruby/ &&\
    chmod -R 775 /usr/local/lib/ruby

WORKDIR $APP_HOME

RUN bundle install --binstubs --path vendor/bundle

USER slapi

EXPOSE 4567

ENTRYPOINT ["supervisord", "-n"]
