# Swift WASM Development Container
# Uses official Swift 6.2.3 with WASM SDK
FROM swift:6.2.3

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    python3 \
    python3-flask \
    && rm -rf /var/lib/apt/lists/*

# Install WASM SDK
RUN swift sdk install \
    https://download.swift.org/swift-6.2.3-release/wasm-sdk/swift-6.2.3-RELEASE/swift-6.2.3-RELEASE_wasm.artifactbundle.tar.gz \
    --checksum 394040ecd5260e68bb02f6c20aeede733b9b90702c2204e178f3e42413edad2a

# Set up Raven package structure
WORKDIR /Raven

# Copy root Raven package files
COPY Package.swift Package.resolved* ./
COPY Sources ./Sources

# Copy TodoApp package
COPY Examples/TodoApp/Package.swift Examples/TodoApp/Package.swift
COPY Examples/TodoApp/Sources Examples/TodoApp/Sources

# Set working directory to TodoApp
WORKDIR /Raven/Examples/TodoApp

# Resolve dependencies
RUN swift package resolve

# Build script that builds WASM and serves
COPY Examples/TodoApp/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
