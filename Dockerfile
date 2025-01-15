FROM ubuntu:24.04
WORKDIR /workdir
COPY . /workdir
COPY .config/hosts /etc/ansible/hosts
RUN apt update && apt install --yes \
    ansible \
    ansible-lint \
    curl \
    gnupg \
    make \
    software-properties-common
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt-get update && \
    apt-get install --yes terraform
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
CMD ["make"]
