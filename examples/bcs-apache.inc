<Proxy *>
  Order deny,allow
  Allow from all
</Proxy>
ProxyRequests Off
ProxyPreserveHost On
ProxyPass / http://localhost:8080/ keepalive=On
ProxyPassReverse / http://localhost:8080/
RequestHeader set X-Forwarded-Proto "http"