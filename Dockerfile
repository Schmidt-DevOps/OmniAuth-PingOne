FROM ruby:3-alpine
RUN apk add --update build-base

RUN mkdir /usr/src/app 
ADD . /usr/src/app/ 
WORKDIR /usr/src/app/
# Install gems
RUN bundle update --bundler && \
    bundle install -j $(nproc) --path vendor && \
    apk del build-base && rm -rf /usr/local/lib/ruby/gems/*/cache/* /var/cache/apk/* /tmp/* /var/tmp/* && \
    chmod u+x /usr/src/app/entrypoint.sh
ENTRYPOINT ["/bin/sh", "-c"]
CMD ["/usr/src/app/entrypoint.sh"]