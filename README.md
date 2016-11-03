# Description

This repo contains all the Nginx configuration files for EduardoChat.

# Useful commands

To start NGINX (We are using [OpenResty](https://github.com/IIC2173-2016-2/openresty-eduardochat)) execute **in this folder** the command
```{r, engine='sh', count_lines}
nginx -p `pwd`/ -c conf/nginx.conf
```
To restart
```{r, engine='sh', count_lines}
sudo nginx -s reload
```
