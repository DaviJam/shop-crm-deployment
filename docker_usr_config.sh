sudo groupadd -f docker;
sudo chown root:docker /var/run/docker.sock;
sudo usermod -a -G docker "$(whoami)";
newgrp docker;
sudo systemctl restart docker;