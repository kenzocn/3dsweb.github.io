#/bin/sh

socks_port="3000"
socks_user="admin"
socks_pass="admin"

ips=(
149.248.9.200
149.28.95.181
)

ips=(
$(hostname -I)
)
# Xray Installation
wget -O /usr/local/bin/xray https://cdn.jsdelivr.net/gh/none-blue/xray-amd64@main/xray
chmod +x /usr/local/bin/xray

cat <<EOF > /etc/systemd/system/xray.service
[Unit]
Description=The Xray Proxy Serve
After=network-online.target

[Service]
ExecStart=/usr/local/bin/xray -c /etc/xray/serve.toml
ExecStop=/bin/kill -s QUIT $MAINPID
Restart=always
RestartSec=15s

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable xray

# Xray Configuration
mkdir -p /etc/xray
echo -n "" > /etc/xray/serve.toml
for ((i = 0; i < ${#ips[@]}; i++)); do
cat <<EOF >> /etc/xray/serve.toml
[[inbounds]]
listen = "${ips[i]}"
port = $socks_port
protocol = "socks"
tag = "$((i+1))"
[inbounds.settings]
auth = "password"
udp = true
ip = "${ips[i]}"
[[inbounds.settings.accounts]]
user = "$socks_user"
pass = "$socks_pass"

[[routing.rules]]
type = "field"
inboundTag = "$((i+1))"
outboundTag = "$((i+1))"

[[outbounds]]
sendThrough = "${ips[i]}"
protocol = "freedom"
tag = "$((i+1))"

EOF
done

systemctl stop xray
systemctl start xray
#systemctl status xray


for ((i = 0; i < ${#ips[@]}; i++)); do
echo socks5://$socks_user:$socks_pass@${ips[i]}:$socks_port
curl ip.me -x socks5://$socks_user:$socks_pass@${ips[i]}:$socks_port
done

for ((i = 0; i < ${#ips[@]}; i++)); do
echo socks://`echo "$socks_user:$socks_pass@${ips[i]}:$socks_port" | base64`#$((i+1))
done