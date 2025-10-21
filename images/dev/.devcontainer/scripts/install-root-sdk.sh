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