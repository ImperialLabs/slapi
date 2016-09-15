FROM ruby:2.3

RUN apt-get update -qq && \
    apt-get autoremove -y && \
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Setup App Environment and User
ENV APP_HOME /slapi

RUN mkdir $APP_HOME && \
    adduser slapi --disabled-password --gecos "" && \
    chown -R slapi:slapi $APP_HOME && \
    echo "slapi            ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/
ADD *.gemspec $APP_HOME/

RUN bundle install

# Dowgrade to App User
USER slapi

ADD . $APP_HOME

EXPOSE 4568
ENV RACK_ENV=production

CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "4568"]
