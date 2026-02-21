#!/bin/bash
# deploy.sh

SERVER="konnect"
APP_DIR="~"
BINARY="serverBinaryNew"

go build -o $BINARY

# Upload binary
scp ./$BINARY .env $SERVER:$APP_DIR/

# Restart service remotely
ssh $SERVER << EOF
sudo systemctl stop serverBinary.service
cd $APP_DIR
mv serverBinary serverBinaryOld
mv $BINARY serverBinary
sudo systemctl start serverBinary.service
EOF

echo "Deployment of $BINARY complete!"
