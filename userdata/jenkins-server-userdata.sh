#!/bin/bash
# ----------------------------------------------------
# EC2 UserData: OpenJDK 17 + Maven + Jenkins (8080)
# ----------------------------------------------------

set -e

echo "Updating system..."
apt update -y

# ----------------------------------------------------
# Install Java 17, Maven, utilities
# ----------------------------------------------------
echo "Installing OpenJDK 17, Maven, and utilities..."
apt install -y \
  openjdk-17-jdk \
  maven \
  wget \
  curl \
  gnupg \
  tar

java -version
mvn -version

# ----------------------------------------------------
# Install Jenkins
# ----------------------------------------------------
echo "Installing Jenkins..."

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ \
  | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

apt update -y
apt install -y jenkins

# --
echo "----------------------------------------------------"
echo "Setup complete:"
echo " - Java 17 installed"
echo " - Maven installed"

echo "----------------------------------------------------"
