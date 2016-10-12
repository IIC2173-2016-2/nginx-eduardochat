upstream myapp {
    least_conn;
    server assw10.ing.puc.cl:3000;
    server assw11.ing.puc.cl:3000;
    server assw12.ing.puc.cl:3000;
    sticky;
}
upstream login-app{
   server assw9.ing.puc.cl:3000;
}
lua_package_path "/usr/local/lib/lua/5.1/?.lua;;";
server {
  listen 80 default_server;
  listen [::]:80 default_server;

  server_name test.com www.test.com;

  location / {
         proxy_pass http://myapp;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection 'upgrade';
          proxy_set_header Host $host;
          proxy_cache_bypass $http_upgrade;

  }

  location /chat {
          proxy_pass http://myapp;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection 'upgrade';
          proxy_set_header Host $host;
          proxy_cache_bypass $http_upgrade;
  }
  location /users {
          proxy_pass http://login-app;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection 'upgrade';
          proxy_set_header Host $host;
          proxy_cache_bypass $http_upgrade;
  }

  location /test {
    content_by_lua_block {
            local redis = require "redis"
            local red = redis:new()
            local ok,err = red:connect("127.0.0.1",6379)
            if not ok then
                    ngx.say("failed to connect: ",err)
                    return
            end
            ngx.say("me pude conectar al parecer")
            red:select(0)
            red:set("test","Its workiiiiiiing gud")
            local value = red:get("test")
            ngx.say(value)
    }
  }
}
