# Start from the official 'act' environment
FROM catthehacker/ubuntu:act-latest

# Install AWS CLI (v2)
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && sudo ./aws/install \
    && rm -rf awscliv2.zip