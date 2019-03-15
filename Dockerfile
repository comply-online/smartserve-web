FROM openresty/openresty:alpine-fat

# allowed domains should be lua match pattern
ENV DIFFIE_HELLMAN='' ALLOWED_DOMAINS='.*' AUTO_SSL_VERSION='0.11.1' FORCE_HTTPS='true' SITES=''

# Here we install open resty and generate dhparam.pem file.
# You can specify DIFFIE_HELLMAN=true to force regeneration of that file on first run
# also we create fallback ssl keys
RUN apk --no-cache add bash openssl git \
  && /usr/local/openresty/luajit/bin/luarocks install lua-resty-auto-ssl $AUTO_SSL_VERSION \
  && openssl req -new -newkey rsa:1024 -days 3650 -nodes -x509 \
  -subj '/CN=sni-support-required-for-valid-ssl' \
  -keyout /etc/ssl/resty-auto-ssl-fallback.key \
  -out /etc/ssl/resty-auto-ssl-fallback.crt \
  && openssl dhparam -out /usr/local/openresty/nginx/conf/dhparam.pem 1024 \
  && rm /etc/nginx/conf.d/default.conf
# Last line is about removing default open resty configuration, we'll conditionally add modified version in entrypoint.sh

RUN mkdir /temp
RUN git clone https://comply-online:This%20Is%20Compliance123!@github.com/comply-online/smartserve-web.git /temp
RUN yes | cp -prf temp/* /usr/local/openresty/nginx/html
RUN rm -rf /temp

COPY nginx.conf snippets /usr/local/openresty/nginx/conf/
COPY entrypoint.sh /entrypoint.sh

VOLUME /etc/resty-auto-ssl

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]