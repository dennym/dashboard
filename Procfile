web: bundle exec thin start -R config.ru -e $RACK_ENV -p $PORT
release: curl -i -d "{ \"auth_token\": \"${AUTH_TOKEN}\", \"event\": \"reload\" }" "${APP_URL}/dashboards/*"
