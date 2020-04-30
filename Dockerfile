FROM jenkinsci/jnlp-slave:4.0.1-1

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV AWS_CLI_VERSION=1.16.272 \
    CT_VERSION=3.0.0-beta.2 \
    HADOLINT_VERSION=v1.17.5 \
    HELMFILE_VERSION=v0.100.1 \
    HELM_VERSION=v3.1.1 \
    HELM_PLGN_DIFF_VERSION=v3.1.1 \
    HELM_PLGN_SECRET_VERSION=2.0.2 \
    HELM_PLGN_PUSH_VERSION=0.8.1 \
    KUBECTL_VERSION=v1.14.1 \
    PRE_COMMIT_VERSION=1.20.0 \
    SOPS_PLUGIN_VERSION=v0.4.1 \
    SOPS_VERSION=v3.5.0 \
    YAML_LINT_VERSION=1.13.0 \
    YAMALE_VERSION=1.8.0

# hadolint
RUN curl -Lo /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/download/$HADOLINT_VERSION/hadolint-Linux-x86_64 && \
# aws-iam-authenticator
curl -Lo /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator && \
# kubectl
curl -Lo /usr/local/bin/kubectl  https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl && \
# helm
curl -Lo /home/jenkins/helm.tar.gz https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz && \
tar -xzf /home/jenkins/helm.tar.gz -C /home/jenkins/ && \
mv /home/jenkins/linux-amd64/helm /usr/local/bin/ && rm -r /home/jenkins/helm.tar.gz /home/jenkins/linux-amd64/ && \
# helmfile
curl -Lo /usr/local/bin/helmfile https://github.com/roboll/helmfile/releases/download/$HELMFILE_VERSION/helmfile_linux_amd64 && \
# sops
curl -Lo /usr/local/bin/sops https://github.com/mozilla/sops/releases/download/$SOPS_VERSION/sops-$SOPS_VERSION.linux && \
# ct
curl -Lo /home/jenkins/ct.tar.gz https://github.com/helm/chart-testing/releases/download/v${CT_VERSION}/chart-testing_${CT_VERSION}_linux_amd64.tar.gz && \
tar -zxvf ct.tar.gz ct && \
mv /home/jenkins/ct /usr/local/bin/ && rm /home/jenkins/ct.tar.gz  && \
# grant permissions to execute files
chmod -R +x /usr/local/bin/

RUN apt-get update && apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \
      python-crcmod=1.7-2+b2 \
      python-pip=9.0.1-2+deb9u1 \
      python-setuptools=33.1.1-1 && \
    pip install --upgrade pip==18.1 \
            awscli==$AWS_CLI_VERSION && \
    rm -f /usr/bin/pip && hash -r && \
    rm -rf /var/lib/apt/lists/* \
           /var/cache/apt/archives/*.deb \
           /var/cache/apt/archives/partial/*.deb \
           /var/cache/apt/*.bin \
           /root/.cache

RUN pip install yamllint==$YAML_LINT_VERSION \
                yamale==$YAMALE_VERSION

USER 1000
# helm-plugins
RUN export HOME=/home/jenkins && \
    helm plugin install https://github.com/databus23/helm-diff --version $HELM_PLGN_DIFF_VERSION --debug && \
    helm plugin install https://github.com/chartmuseum/helm-push --version $HELM_PLGN_PUSH_VERSION --debug && \
    helm plugin install https://github.com/futuresimple/helm-secrets --version $HELM_PLGN_SECRET_VERSION --debug
    
RUN mkdir -p /home/jenkins/.ssh && echo -e "Host *\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile /dev/null" >> /home/jenkins/.ssh/config

# Add configs for ct
COPY ["./etc/ct/chart_schema.yaml", "./etc/ct/lintconf.yaml", "/etc/ct/"]
