FROM jenkins/jenkins:2.555.2-jdk21
USER root

RUN apt-get update && apt-get install -y lsb-release ca-certificates curl vim wget gnupg git awscli jq less && \
    # Terraform repo
    wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list && \
    # Add ngrok's official GPG key and repository [26]
    curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
        | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
        && echo "deb https://ngrok-agent.s3.amazonaws.com bookworm main" \
        | tee /etc/apt/sources.list.d/ngrok.list && \
    # Install ngrok [26]
    apt-get update && apt-get install -y ngrok && \
    # Docker repo
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/debian $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    # Install packages
    apt-get update && apt-get install -y terraform docker-ce-cli && \
    apt-get clean && rm -rf /var/lib/apt/lists/* 

# Ensure JENKINS_HOME exists with correct ownership before plugin install
RUN mkdir -p /var/jenkins_home && \
    chown -R jenkins:jenkins /var/jenkins_home && \
    chmod -R u+rwx /var/jenkins_home \
    chown -R jenkins:jenkins /app/Terraform-Project

WORKDIR /var/jenkins_home/workspace

USER jenkins

RUN jenkins-plugin-cli --plugins "blueocean docker-workflow json-path-api"

