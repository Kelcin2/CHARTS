#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions - all output to stderr to avoid being captured by command substitution
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Download and install gopass
install_gopass() {
    local download_url="${GOPASS_DOWNLOAD_URL:-}"
    local install_dir="/home/node/node/bin"
    local temp_dir

    if [[ -z "$download_url" ]]; then
        log_warn "GOPASS_DOWNLOAD_URL not set, skipping gopass download"
        return 0
    fi
    
    # Check if gopass already exists
    if command -v gopass &> /dev/null; then
        local gopass_version
        gopass_version=$(gopass version 2>&1 | head -1)
        log_warn "gopass already installed: ${gopass_version}"
        return 0
    fi
    
    log_info "gopass not found, downloading from ${download_url}..."
    
    # Create temp directory
    temp_dir=$(mktemp -d)
    
    # Download the tarball
    if ! curl -s -L --fail "$download_url" -o "${temp_dir}/gopass.tar.gz"; then
        log_error "Failed to download gopass from ${download_url}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Extract the tarball
    log_info "Extracting gopass..."
    if ! tar -xzf "${temp_dir}/gopass.tar.gz" -C "$temp_dir"; then
        log_error "Failed to extract gopass tarball"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Find the gopass binary in extracted files
    local gopass_binary
    gopass_binary=$(find "$temp_dir" -name "gopass" -type f | head -1)
    
    if [[ -z "$gopass_binary" ]]; then
        log_error "gopass binary not found in extracted files"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Create install directory if not exists
    mkdir -p "$install_dir"
    
    # Move gopass binary to install directory
    log_info "Installing gopass to ${install_dir}/gopass..."
    mv "$gopass_binary" "${install_dir}/gopass"
    chmod 755 "${install_dir}/gopass"
    
    # Clean up temp directory
    rm -rf "$temp_dir"
    
    # Verify installation
    if ! "${install_dir}/gopass" version &> /dev/null; then
        log_error "gopass installation verification failed"
        return 1
    fi
    log_info "$(gopass version 2>&1 | head -1)"
    log_info "gopass installed successfully to ${install_dir}/gopass"
}

# Check if required environment variables are set
check_env_vars() {
    local missing_vars=()
    
    if [[ -z "${GOPASS_HOMEDIR:-}" ]]; then
        missing_vars+=("GOPASS_HOMEDIR")
    fi

    if [[ -z "${GOPASS_AGE_PASSWORD:-}" ]]; then
        missing_vars+=("GOPASS_AGE_PASSWORD")
    fi
    
    if [[ -z "${KUBERNETES_SERVICE_HOST:-}" ]]; then
        missing_vars+=("KUBERNETES_SERVICE_HOST")
    fi
    
    if [[ ${#missing_vars[@]} -ne 0 ]]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        exit 1
    fi
}

# Check if required commands exist
check_dependencies() {
    local deps=("gopass" "age" "age-keygen" "curl" "python3")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        else
            log_info "${dep} detected successfully"
        fi
    done
    
    if [[ ${#missing_deps[@]} -ne 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        exit 1
    fi

    log_info "All dependencies detected successfully"
}

# Download and install age
install_age() {
    local download_url="${GOPASS_AGE_DOWNLOAD_URL:-}"
    local install_dir="/home/node/node/bin"
    local temp_dir

    if [[ -z "$download_url" ]]; then
        log_warn "GOPASS_AGE_DOWNLOAD_URL not set, skipping age download"
        return 0
    fi

    # Check if both age and age-keygen already exist
    if command -v age &> /dev/null && command -v age-keygen &> /dev/null; then
        local age_version
        age_version=$(age --version 2>&1 | head -1)
        log_warn "age already installed: ${age_version}"
        log_warn "age-keygen already installed: $(age-keygen --version 2>&1 | head -1)"
        return 0
    fi

    log_info "age/age-keygen not found, downloading from ${download_url}..."

    # Create temp directory
    temp_dir=$(mktemp -d)

    # Download the tarball
    if ! curl -s -L --fail "$download_url" -o "${temp_dir}/age.tar.gz"; then
        log_error "Failed to download age from ${download_url}"
        rm -rf "$temp_dir"
        return 1
    fi

    # Extract the tarball
    log_info "Extracting age..."
    if ! tar -xzf "${temp_dir}/age.tar.gz" -C "$temp_dir"; then
        log_error "Failed to extract age tarball"
        rm -rf "$temp_dir"
        return 1
    fi

    # Find the age binary in extracted files
    local age_binary
    age_binary=$(find "$temp_dir" -name "age" -type f | head -1)

    if [[ -z "$age_binary" ]]; then
        log_error "age binary not found in extracted files"
        rm -rf "$temp_dir"
        return 1
    fi

    # Create install directory if not exists
    mkdir -p "$install_dir"

    # Move age binary to install directory
    log_info "Installing age to ${install_dir}/age..."
    mv "$age_binary" "${install_dir}/age"
    chmod 755 "${install_dir}/age"

    # Find and install age-keygen binary
    local age_keygen_binary
    age_keygen_binary=$(find "$temp_dir" -name "age-keygen" -type f | head -1)

    if [[ -z "$age_keygen_binary" ]]; then
        log_error "age-keygen binary not found in extracted files"
        rm -rf "$temp_dir"
        return 1
    fi

    mv "$age_keygen_binary" "${install_dir}/age-keygen"
    chmod 755 "${install_dir}/age-keygen"

    # Clean up temp directory
    rm -rf "$temp_dir"

    # Verify installation
    if ! "${install_dir}/age" --version &> /dev/null; then
        log_error "age installation verification failed"
        return 1
    fi
    if ! "${install_dir}/age-keygen" --version &> /dev/null; then
        log_error "age-keygen installation verification failed"
        return 1
    fi
    log_info "$(age --version 2>&1 | head -1)"
    log_info "$(age-keygen --version 2>&1 | head -1)"
    log_info "age and age-keygen installed successfully to ${install_dir}"
}

# Initialize gopass with age backend
init_gopass() {
    log_info "Initializing gopass with age backend..."

    local age_recipients_file="${GOPASS_HOMEDIR}/.local/share/gopass/stores/root/.age-recipients"

    if [[ -f "$age_recipients_file" ]]; then
        log_warn "Gopass already initialized, skipping..."
    else
        gopass --yes setup --crypto age
        log_info "Gopass initialized successfully with age backend"
    fi
    
    # disabled git
    local gopass_root_store="${GOPASS_HOMEDIR}/.local/share/gopass/stores/root"
    rm -rf "${gopass_root_store}/.git" 2>/dev/null || true
    rm -rf "${gopass_root_store}/.gitattributes" 2>/dev/null || true
    
    gopass config core.autosync false > /dev/null
    log_info "Gopass configuration completed"
}

# Fetch secret from Kubernetes API
fetch_k8s_secret_field() {
    local field_name="$1"
    local secret_name="openclaw-secret"
    
    # Check Kubernetes service account files
    local token_file="/var/run/secrets/kubernetes.io/serviceaccount/token"
    local ca_cert="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
    local namespace_file="/var/run/secrets/kubernetes.io/serviceaccount/namespace"
    
    if [[ ! -f "$token_file" ]]; then
        log_error "Service account token file not found at $token_file"
        return 1
    fi
    
    if [[ ! -f "$ca_cert" ]]; then
        log_error "CA certificate not found at $ca_cert"
        return 1
    fi
    
    if [[ ! -f "$namespace_file" ]]; then
        log_error "Namespace file not found at $namespace_file"
        return 1
    fi
    
    local namespace
    namespace=$(cat "$namespace_file")
    log_info "Using namespace: ${namespace}"
    
    log_info "Fetching field '${field_name}' from Kubernetes secret ${secret_name} in namespace ${namespace}..."
    
    local secret_value
    secret_value=$(curl -s --fail --cacert "$ca_cert" \
        -H "Authorization: Bearer $(cat "$token_file")" \
        "https://${KUBERNETES_SERVICE_HOST}/api/v1/namespaces/${namespace}/secrets/${secret_name}" \
        | python3 -c "import sys, json, base64; data=json.load(sys.stdin); print(base64.b64decode(data['data']['${field_name}']).decode())")
    
    if [[ $? -ne 0 ]] || [[ -z "$secret_value" ]]; then
        log_error "Failed to fetch secret field: ${field_name}"
        return 1
    fi
    
    echo "$secret_value"
}

# Insert secret into gopass
insert_secret() {
    local secret_path="$1"
    local secret_value="$2"
    
    if [[ -z "$secret_value" ]]; then
        log_error "Secret value is empty for ${secret_path}"
        return 1
    fi
    
    log_info "Inserting secret into gopass: ${secret_path}"
    echo "$secret_value" | gopass insert --force "$secret_path"
    
    if [[ $? -eq 0 ]]; then
        log_info "Successfully inserted secret: ${secret_path}"
    else
        log_error "Failed to insert secret: ${secret_path}"
        return 1
    fi
}

# Main function
main() {
    log_info "Starting gopass initialization script..."

    # Install gopass and age if download URLs are provided
    install_age
    install_gopass

    # Pre-flight checks
    check_dependencies
    check_env_vars
    
    # Initialize gopass with age backend
    init_gopass
    
    # Fetch auth token from Kubernetes and insert into gopass
    log_info "Fetching auth token from Kubernetes..."
    local auth_token
    if auth_token=$(fetch_k8s_secret_field "_authToken"); then
        insert_secret "openclaw/auth-token" "$auth_token"
    else
        log_error "Failed to retrieve auth token"
        exit 1
    fi
    
    # Fetch API key from Kubernetes and insert into gopass
    log_info "Fetching API key from Kubernetes..."
    local api_key
    if api_key=$(fetch_k8s_secret_field "_apiKey"); then
        insert_secret {{ .id | quote }} "$api_key"
    else
        log_error "Failed to retrieve API key"
        exit 1
    fi
    
    log_info "All operations completed successfully!"

    log_info "Starting OpenClaw process..."
    exec node openclaw.mjs gateway
}

# Run main function
main