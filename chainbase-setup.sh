#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Display logo
echo -e "${BLUE}"
cat << "EOF"
                                               _____   _                    _    
     /\                                       / ____| | |                  | |   
    /  \     _ __    __ _    ___    _ __     | (___   | |_    __ _   _ __  | | __
   / /\ \   | '__|  / _ |  / _ \  | '_ \     \___ \  | __|  / _ | | '__| | |/ /
  / ____ \  | |    | (_| | | (_) | | | | |    ____) | | |_  | (_| | | |    |   < 
 /_/    \_\ |_|     \__, |  \___/  |_| |_|   |_____/   \__|  \__,_| |_|    |_|\_\
                     __/ |                                                       
                    |___/                                                        
EOF

sleep 3

echo -e "${NC}"

# Print startup message
echo -e "${GREEN}Running chainbase AVS Operator...${NC}"

# Install Dependencies
echo -e "${YELLOW}Installing Dependencies...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt install ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4 -y

# Install Docker
echo -e "${YELLOW}Installing Docker...${NC}"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
docker version

# Install Docker-Compose
echo -e "${YELLOW}Installing Docker-Compose...${NC}"
VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version

# Docker Permission to user
sudo groupadd docker
sudo usermod -aG docker $USER

# Install Go
echo -e "${YELLOW}Installing Go...${NC}"
sudo rm -rf /usr/local/go
curl -L https://go.dev/dl/go1.22.4.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> $HOME/.bash_profile
source $HOME/.bash_profile
go version

#!/bin/bash

# Check if 'eigenlayer' exists and delete it
if [ -e "eigenlayer" ]; then
    echo -e "${YELLOW}Found 'eigenlayer'. Deleting...${NC}"
    rm -rf eigenlayer
    echo -e "${GREEN}'eigenlayer' deleted successfully.${NC}"
else
    echo -e "${CYAN}'eigenlayer' not found. Skipping deletion.${NC}"
fi

# Check if '.eigenlayer' exists and delete it
if [ -d ".eigenlayer" ]; then
    echo -e "${YELLOW}Found '.eigenlayer'. Deleting...${NC}"
    rm -rf .eigenlayer
    echo -e "${GREEN}'.eigenlayer' deleted successfully.${NC}"
else
    echo -e "${CYAN}'.eigenlayer' not found. Skipping deletion.${NC}"
fi

# Check if eigenlayer exists
  echo -e "${YELLOW}Installing EigenLayer CLI...${NC}"
  curl -sSfL https://raw.githubusercontent.com/layr-labs/eigenlayer-cli/master/scripts/install.sh | sh -s
  export PATH=$PATH:~/bin
  eigenlayer --version


# Cloning Chainbase AVS repo
echo -e "${YELLOW}Cloning Chainbase AVS repository...${NC}"
git clone https://github.com/chainbase-labs/chainbase-avs-setup
cd chainbase-avs-setup/holesky

# Key Management
echo -e "${BLUE}Do you want to Import keys, Create new keys, or have you already Imported?${NC}"
select option in "Import" "Create" "Already Imported"; do
  case $option in
    Import)
      read -p "Enter your private key: " PRIVATEKEY
      eigenlayer operator keys import --key-type ecdsa opr "$PRIVATEKEY"
      break
      ;;
    Create)
      eigenlayer operator keys create --key-type ecdsa opr
      read -p "Have you backed up your keys? (yes/no): " backup
      if [ "$backup" != "yes" ]; then
        echo -e "${RED}Please back up your keys before proceeding.${NC}"
        exit 1
      fi
      break
      ;;
    "Already Imported")
      echo -e "${GREEN}Skipping key creation/import...${NC}"
      break
      ;;
    *)
      echo -e "${RED}Invalid option. Please choose 1, 2, or 3.${NC}"
      ;;
  esac
done


# Funding EigenLayer Ethereum Address
echo -e "${BLUE}You need to fund your Eigenlayer address with at least 1 Holesky ETH . Did you fund your address (yes/no)${NC}"
read -p "Choice: " fund_choice
if [ "$fund_choice" == "yes" ]; then
  echo -e "${YELLOW}Please fund your address before continuing.${NC}"
fi

# Configure & Register Operator
echo -e "${YELLOW}Configuring & registering operator...${NC}"
eigenlayer operator config create

# Edit metadata.json
echo -e "${YELLOW}Please provide the following information to metadata.json and after that copy the your provided data and create a metadata file on your github !:${NC}"
read -p "Name: " name
read -p "Website: " website
read -p "Description: " description
read -p "Logo URL: " logo
read -p "Twitter: " twitter
cat << EOF > metadata.json
{
  "name": "$name",
  "website": "$website",
  "description": "$description",
  "logo": "$logo",
  "twitter": "$twitter"
}
EOF

# Upload metadata file to GitHub and edit operator.yaml
echo -e "${YELLOW}Upload the metadata file to your GitHub profile and provide the link:${NC}"
read -p "GitHub Metadata URL: " metadata_url
sed -i "s|metadata_url:.*|metadata_url: \"$metadata_url\"|" operator.yaml

# Running Eigenlayer Holesky Node
echo -e "${YELLOW}Running Eigenlayer Holesky Node...${NC}"
eigenlayer operator register operator.yaml
eigenlayer operator status operator.yaml

# Config Chainbase AVS and Edit .env File
echo -e "${GREEN}Configuring Chainbase AVS...${NC}"

echo -e "${CYAN}Please enter your Eigenlayer password:${NC}"
read -s eigenlayer_password
cat <<EOL >> .env
# Chainbase AVS Image
MAIN_SERVICE_IMAGE=repository.chainbase.com/network/chainbase-node:testnet-v0.1.7
FLINK_TASKMANAGER_IMAGE=flink:latest
FLINK_JOBMANAGER_IMAGE=flink:latest
PROMETHEUS_IMAGE=prom/prometheus:latest

MAIN_SERVICE_NAME=chainbase-node
FLINK_TASKMANAGER_NAME=flink-taskmanager
FLINK_JOBMANAGER_NAME=flink-jobmanager
PROMETHEUS_NAME=prometheus

# FLINK CONFIG
FLINK_CONNECT_ADDRESS=flink-jobmanager
FLINK_JOBMANAGER_PORT=8081
NODE_PROMETHEUS_PORT=9091
PROMETHEUS_CONFIG_PATH=./prometheus.yml

# Chainbase AVS mounted locations
NODE_APP_PORT=8080
NODE_ECDSA_KEY_FILE=/app/operator_keys/ecdsa_key.json
NODE_LOG_DIR=/app/logs

# Node logs configs
NODE_LOG_LEVEL=debug
NODE_LOG_FORMAT=text

# Metrics specific configs
NODE_ENABLE_METRICS=true
NODE_METRICS_PORT=9092

# holesky smart contracts
AVS_CONTRACT_ADDRESS=0x5E78eFF26480A75E06cCdABe88Eb522D4D8e1C9d
AVS_DIR_CONTRACT_ADDRESS=0x055733000064333CaDDbC92763c58BF0192fFeBf

# TODO: Operators need to point this to a working chain rpc
NODE_CHAIN_RPC=https://rpc.ankr.com/eth_holesky
NODE_CHAIN_ID=17000

# TODO: Operators need to update this to their own paths
USER_HOME=\$HOME
EIGENLAYER_HOME=\${USER_HOME}/.eigenlayer
CHAINBASE_AVS_HOME=\${EIGENLAYER_HOME}/chainbase/holesky

NODE_LOG_PATH_HOST=\${CHAINBASE_AVS_HOME}/logs

# TODO: Operators need to update this to their own keys
NODE_ECDSA_KEY_FILE_HOST=\${EIGENLAYER_HOME}/operator_keys/opr.ecdsa.key.json

# TODO: Operators need to add password to decrypt the above keys
# If you have some special characters in password, make sure to use single quotes
NODE_ECDSA_KEY_PASSWORD=${eigenlayer_password}
EOL

# Create docker-compose.yml file
echo -e "${GREEN}Creating docker-compose.yml file...${NC}"

rm -rf docker-compose.yml

cat <<EOL > docker-compose.yml
services:
  prometheus:
    image: \${PROMETHEUS_IMAGE}
    container_name: \${PROMETHEUS_NAME}
    env_file:
      - .env
    volumes:
      - "\${PROMETHEUS_CONFIG_PATH}:/etc/prometheus/prometheus.yml"
    command:
      - "--enable-feature=expand-external-labels"
      - "--config.file=/etc/prometheus/prometheus.yml"
    ports:
      - "9091:9090"
    networks:
      - chainbase
    restart: unless-stopped

  flink-jobmanager:
    image: \${FLINK_JOBMANAGER_IMAGE}
    container_name: \${FLINK_JOBMANAGER_NAME}
    env_file:
      - .env
    ports:
      - "8081:8081"
    command: jobmanager
    networks:
      - chainbase
    restart: unless-stopped

  flink-taskmanager:
    image: \${FLINK_JOBMANAGER_IMAGE}
    container_name: \${FLINK_TASKMANAGER_NAME}
    env_file:
      - .env
    depends_on:
      - flink-jobmanager
    command: taskmanager
    networks:
      - chainbase
    restart: unless-stopped

  chainbase-node:
    image: \${MAIN_SERVICE_IMAGE}
    container_name: \${MAIN_SERVICE_NAME}
    command: ["run"]
    env_file:
      - .env
    ports:
      - "8080:8080"
      - "9092:9092"
    volumes:
      - "\${NODE_ECDSA_KEY_FILE_HOST:-./opr.ecdsa.key.json}:\${NODE_ECDSA_KEY_FILE}"
      - "\${NODE_LOG_PATH_HOST}:\${NODE_LOG_DIR}:rw"
    depends_on:
      - prometheus
      - flink-jobmanager
      - flink-taskmanager
    networks:
      - chainbase
    restart: unless-stopped

networks:
  chainbase:
    driver: bridge
EOL

# Create folders for docker
echo -e "${GREEN}Creating necessary folders for Docker...${NC}"
source .env && mkdir -pv ${EIGENLAYER_HOME} ${CHAINBASE_AVS_HOME} ${NODE_LOG_PATH_HOST}

# Function to update docker compose command in script
fix_docker_compose() {
    FILE="chainbase-avs.sh"
    echo -e "${RED}Detected 'unknown shorthand flag: d in -d' error. Updating 'docker compose' to 'docker-compose' in $FILE...${NC}"
    
    # Replace 'docker compose' with 'docker-compose' using sed
    sed -i 's/docker compose/docker-compose/g' "$FILE"
    
    echo -e "${GREEN}Update completed. Retrying...${NC}"
}

# Starting docker to prevent problems 
echo -e "${GREEN}Starting Docker ...${NC}"
systemctl start docker

# Give permissions to bash script
echo -e "${GREEN}Giving execute permissions to chainbase-avs.sh...${NC}"
chmod +x ./chainbase-avs.sh

# Update prometheus.yml
echo -e "${CYAN}Please enter your operator address for Prometheus configuration:${NC}"
read operator_address

echo -e "${GREEN}Updating prometheus.yml...${NC}"

cat <<EOL > prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    operator: "${operator_address}"

remote_write:
  - url: http://testnet-metrics.chainbase.com:9090/api/v1/write
    write_relabel_configs:
      - source_labels: [job]
        regex: "chainbase-avs"
        action: keep

scrape_configs:
  - job_name: "chainbase-avs"
    metrics_path: /metrics
    static_configs:
      - targets: ["chainbase-node:9092"]
EOL

# Update docker compose command before running AVS
fix_docker_compose

# Run Chainbase AVS
echo -e "${GREEN}Registering AVS...${NC}"
./chainbase-avs.sh register

echo -e "${GREEN}Running AVS...${NC}"
./chainbase-avs.sh run

# AVS running successfully message
echo -e "${GREEN}AVS running successfully!${NC}"

# Get AVS link
echo -e "${GREEN}Fetching AVS link...${NC}"
export PATH=$PATH:~/bin
eigenlayer operator status operator.yaml

# Checking Operator Health
sleep 2
echo -e "${YELLOW}Checking operator health on port 8080...${NC}"
curl -i localhost:8080/eigen/node/health

# Checking the docker containers
echo -e "${YELLOW}Checking Docker containers...${NC}"
docker ps

echo -e "${GREEN}Setup complete!${NC}"

