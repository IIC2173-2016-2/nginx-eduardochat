upstream myapp {
    least_conn;
    server assw10.ing.puc.cl:3000;
    server assw11.ing.puc.cl:3000;
    server assw12.ing.puc.cl:3000;
    #sticky;
}
upstream mydashboard {
    least_conn;
    server assw10.ing.puc.cl:8081;
    server assw11.ing.puc.cl:8081;
    server assw12.ing.puc.cl:8081;
    #sticky;
}
upstream foursquare{
    least_conn;
    server assw10.ing.puc.cl:9001;
    server assw11.ing.puc.cl:9001;
    server assw12.ing.puc.cl:9001;
    #sticky;
}
upstream arquicoins {
    least_conn;
    server assw10.ing.puc.cl:8083;
    server assw11.ing.puc.cl:8083;
    server assw12.ing.puc.cl:8083;
}
upstream myapp1 {
    server assw10.ing.puc.cl:3000;

    server assw11.ing.puc.cl:3000 backup;
}
upstream myapp2 {
    server assw11.ing.puc.cl:3000;

    server assw12.ing.puc.cl:3000 backup;

}
upstream myapp3 {
    server assw12.ing.puc.cl:3000;

    server assw10.ing.puc.cl:3000 backup;

}
upstream login-app{
    server assw9.ing.puc.cl:3000;
}
lua_package_path "/usr/local/lib/lua/5.1/?.lua;;";

server {
    listen 80;
    server_name assw9.ing.puc.cl;
    return 301 https://assw9.ing.puc.cl$request_uri;
}

server {
    listen 443 ssl;
    server_name assw9.ing.puc.cl;

    ssl_certificate /etc/letsencrypt/live/assw9.ing.puc.cl/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/assw9.ing.puc.cl/privkey.pem;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;

    location / {
        proxy_pass http://mydashboard;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
    location /arquicoins {
        proxy_pass http://arquicoins;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
    location /loaderio-f77df4b9074312f478d7f2f24b10a2a5.txt {
        root /home/administrator/validation-files/;
    }
    location /chat {
        proxy_pass http://myapp;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
    location ~ /chat/chat_room/([a-zA-Z0-9]+)(/.*)? {
        set $chat_n $1;
        set_by_lua $chat_server '
            number = 0
            for i = 1,string.len(ngx.var.chat_n)
            do
                number = number + string.byte(ngx.var.chat_n,i)
            end
            return (number%3) +1
        ';
        proxy_pass http://myapp$chat_server;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
    location /api {
        set $chat_n $http_chat_id;
        set_by_lua $chat_server '
            number = 0
            for i = 1,string.len(ngx.var.chat_n)
            do
                number = number + string.byte(ngx.var.chat_n,i)
            end
            return (number%3) +1
        ';
        proxy_pass http://myapp$chat_server;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
    location /api/v1/backup {
        set $chat_n $http_chat_id;
        set_by_lua $chat_server '
            number = 0
            for i = 1,string.len(ngx.var.chat_n)
            do
                number = number + string.byte(ngx.var.chat_n,i)
            end
            number = number + 1
            return (number%3) +1
        ';
        proxy_pass http://myapp$chat_server;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
    location /socket.io {
        if ($http_referer ~ /chat/chat_room/(\d+)) {
            set $chat_n $1;
        }
        set_by_lua $chat_server '
            number = 0
            for i = 1,string.len(ngx.var.chat_n)
            do
                number = number + string.byte(ngx.var.chat_n,i)
            end
            return (number%3) +1
        ';
        proxy_pass http://myapp$chat_server;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
    location /css {
      	proxy_pass http://login-app;
    }
    location /eduardo-chat {
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
    location /foursquare{
        proxy_pass http://foursquare;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
    location /location {
        proxy_pass http://foursquare;
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
            ngx.say("hola")
        }
    }
    location /header_test {
        content_by_lua_block {
            ngx.say("testing_nginx_headers_reading")
            ngx.say(ngx.var.http_chat_id)
            ngx.say(ngx.var.http_test)
            ngx.say(ngx.var.http_TEST)
        }
    }
}
