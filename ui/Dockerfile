FROM alpine
RUN apk update && apk upgrade && apk add g++ make ruby ruby-dev build-base ruby-json && rm -rf /var/cache/apk/* && gem install bundler --no-ri --no-rdoc 
ENV APP_HOME="/app" POST_SERVICE_HOST=post_container POST_SERVICE_PORT=5000 COMMENT_SERVICE_HOST=comment_container COMMENT_SERVICE_PORT=9292
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME
CMD ["puma"]
