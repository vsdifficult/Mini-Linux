# For Ubuntu/Debian systems:
sudo apt-get update
sudo apt-get install -y gnupg software-properties-common

# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install Terraform
sudo apt-get update
sudo apt-get install terraform

terraform --version

bash run.sh --registry rootuser --skip-terraform

# Pull HashiCorp's Terraform container
docker pull hashicorp/terraform:latest

# Create an alias for terraform
echo 'alias terraform="docker run --rm -it -v $(pwd):/workspace -w /workspace hashicorp/terraform:latest"' >> ~/.bashrc
source ~/.bashrc