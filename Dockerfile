FROM ruby:2.3

RUN apt-get update -qq && \
    apt-get install -qq -y nginx && \
    # temporay for debugging remove nano
    apt-get install -qq -y nano && \
    apt-get autoremove -y && \
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Setup App Environment and User
ENV APP_HOME /slapi


RUN mkdir $APP_HOME && \
    adduser slapi --disabled-password --gecos "" && \
    chown -R slapi:slapi $APP_HOME && \
    echo "slapi            ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN mkdir $APP_HOME/tmp && \
    mkdir $APP_HOME/tmp/sockets && \
    mkdir $APP_HOME/tmp/pids && \
    mkdir $APP_HOME/log

WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/
ADD *.gemspec $APP_HOME/

RUN bundle install

ADD nginx-sites.conf /etc/nginx/nginx.conf
ADD . $APP_HOME

#RUN chown -R slapi:slapi $APP_HOME

# Dowgrade to App User
#USER slapi

EXPOSE 4568
EXPOSE 80
ENV RACK_ENV=production

#CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "4568"]

ENTRYPOINT unicorn -c $APP_HOME/unicorn.rb && service nginx start
