FROM lunchiatto/base:0.0 as gems
ADD Gemfile Gemfile.lock ${APP_HOME}/
RUN bundle install

FROM lunchiatto/base:0.0 as assets
COPY --from=gems /usr/local/bundle /usr/local/bundle
ADD . ${APP_HOME}
RUN SECRET_KEY_BASE=for_precompilation \
    AIRBRAKE_PROJECT_KEY=DUMMYKEY \
    AIRBRAKE_PROJECT_ID=12345 \
    rake assets:precompile

from lunchiatto/base:0.0
ADD . ${APP_HOME}
COPY --from=gems /usr/local/bundle /usr/local/bundle
COPY --from=assets ${APP_HOME}/public/assets ${APP_HOME}/public/assets
