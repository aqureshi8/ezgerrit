set -e

# Check if Docker is already installed
if command -v docker &>/dev/null; then
  echo "Docker is already installed."
else
  echo "Installing Docker"
  # Install Docker's official GPG key
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  # Add Docker repository
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update
  sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

  # enable docker start on system startup and start
  sudo systemctl enable docker --now
  sudo usermod -aG docker $USER
  newgrp docker
fi

# Check if Docker Compose is already installed
if command -v docker &>/dev/null; then
  echo "Docker installed successfully."
fi