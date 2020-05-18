.PHONY: apache fpm fpm-alpine

apache:
	docker build --pull -t limesurvey:3-apache 3.0/apache
apache4:
	docker build --pull -t limesurvey:4-apache 4.0/apache
fpm-alpine:
	docker build --pull -t limesurvey:3-fpm 3.0/fpm-alpine
fpm-alpine4:
	docker build --pull -t limesurvey:4-fpm 4.0/fpm-alpine
