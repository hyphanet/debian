#!/bin/sh
# Split up service-wrapper-java sh.script.in into a user-editable config
# component that calls the static code, which needs not be modified.

SRCSH="src/bin/sh.script.in"

if [ ! -f "$SRCSH" ]; then echo >&2 "cwd has no $SRCSH"; exit 1; fi

WRAPPER_SERVICE="$1"
WRAPPER_CMD="$2"

if [ -z "$WRAPPER_SERVICE" ]; then
	WRAPPER_SERVICE="./service-wrapper.sh"
fi

sed -n -e '/^#--/=' "$SRCSH" | {

read L1
read L2

# init.d
{
sed -n -e "1,${L2}p" "$SRCSH"
cat <<EOF

if [ -f "/etc/default/\$APP_NAME" ]; then
	. "/etc/default/\$APP_NAME"
fi

# WRAPPER_PREINIT START
# WRAPPER_PREINIT END

. "$WRAPPER_SERVICE"

EOF
} | sed -e 's|^\(WRAPPER_CMD=\).*|\1"'"$WRAPPER_CMD"'"|g' > init.d
chmod +x init.d

# service-wrapper.sh
{
sed -n -e "1,${L1}p" "$SRCSH"
cat <<'EOF'

if [ -z "$WRAPPER_CONF" ]; then
	echo >&2 "WRAPPER_CONF not set; abort"
	exit 1
fi

EOF
sed -n -e "${L2},\$p" "$SRCSH"
} > service-wrapper.sh
chmod +x service-wrapper.sh

}
