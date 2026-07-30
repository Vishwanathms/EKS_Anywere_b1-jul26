#!/bin/sh

# Default values

export COMPANY=${COMPANY:-Vishwacloudlab}
export APPLICATION=${APPLICATION:-GitOps Demo}
export ENVIRONMENT=${ENVIRONMENT:-Dev}
export VERSION=${VERSION:-v1.0.0}
export COLOR_THEME=${COLOR_THEME:-Blue}
export BUILD_DATE=${BUILD_DATE:-30-Jul-2026}

envsubst \
'$COMPANY $APPLICATION $ENVIRONMENT $VERSION $COLOR_THEME $BUILD_DATE' \
< /usr/share/nginx/html/index.template.html \
> /usr/share/nginx/html/index.html

exec "$@"