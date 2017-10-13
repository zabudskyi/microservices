FROM alpine
RUN apk update && apk upgrade && apk add ruby ruby-dev g++ make ruby-bundler
ENV APP_HOME="/app" POST_SERVICE_HOST=post POST_SERVICE_PORT=5000 COMMENT_SERVICE_HOST=comment COMMENT_SERVICE_PORT=9292
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME
CMD ["puma"]
