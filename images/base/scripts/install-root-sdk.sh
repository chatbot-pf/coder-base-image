# Qodana Cli 설치
echo "Installing Qodana CLI..."
curl -fsSL https://jb.gg/qodana-cli/install | bash
echo "Qodana CLI installed successfully."

# AWS CLI 설치
echo "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws
echo "AWS CLI installed successfully."

# kubectl 설치
echo "Installing kubectl..."
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/
echo "kubectl installed successfully."

# jq 설치 (apt)
echo "Installing jq..."
apt-get update && apt-get install -y jq
echo "jq installed successfully."

# fzf 설치
echo "Installing fzf..."
git clone --depth 1 https://github.com/junegunn/fzf.git /opt/fzf
/opt/fzf/install --all --no-update-rc
ln -s /opt/fzf/bin/fzf /usr/local/bin/fzf
echo "fzf installed successfully."

# Terraform 설치
echo "Installing Terraform..."
TERRAFORM_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r '.current_version')
curl -LO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
mv terraform /usr/local/bin/
rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
echo "Terraform installed successfully."

# ripgrep 설치
echo "Installing ripgrep..."
RIPGREP_VERSION=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | jq -r '.tag_name')
curl -LO "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz"
tar xzf "ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz"
mv "ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl/rg" /usr/local/bin/
rm -rf "ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz" "ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl"
echo "ripgrep installed successfully."

# bat 설치
echo "Installing bat..."
BAT_VERSION=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | jq -r '.tag_name')
curl -LO "https://github.com/sharkdp/bat/releases/download/${BAT_VERSION}/bat-${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz"
tar xzf "bat-${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz"
mv "bat-${BAT_VERSION}-x86_64-unknown-linux-musl/bat" /usr/local/bin/
rm -rf "bat-${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz" "bat-${BAT_VERSION}-x86_64-unknown-linux-musl"
echo "bat installed successfully."

# Cubic 설치
echo "Installing Cubic..."
curl -fsSL https://cubic.dev/install | bash
echo "Cubic installed successfully."