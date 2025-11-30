#!/bin/bash
# ============================================================================
# MAMMON PROTOCOL - GCP Deployment Script
# ============================================================================
# Creates GCP infrastructure for Mammon Protocol testnet:
# - GCP Project: mammon-protocol
# - Compute Engine VM: mammon-testnet (e2-standard-4, Ubuntu 22.04, 100GB SSD)
# - Firewall rules: ports 28080 (P2P), 28081 (RPC)
#
# Prerequisites:
# - gcloud CLI installed and authenticated
# - Billing account linked
#
# Usage: ./gcp_deploy.sh
# ============================================================================

set -e

# Configuration
PROJECT_ID="mammon-protocol"
REGION="us-central1"
ZONE="us-central1-a"
VM_NAME="mammon-testnet"
MACHINE_TYPE="e2-standard-4"  # 4 vCPU, 16GB RAM
BOOT_DISK_SIZE="100GB"
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1"
    exit 1
}

banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║          MAMMON PROTOCOL - GCP Deployment                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_gcloud() {
    log "Checking gcloud authentication..."

    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1 | grep -q "@"; then
        log_error "Not authenticated with gcloud. Run: gcloud auth login"
    fi

    ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1)
    log "Authenticated as: $ACCOUNT"
}

create_project() {
    log "Creating/selecting GCP project: $PROJECT_ID"

    # Check if project exists
    if gcloud projects describe "$PROJECT_ID" &>/dev/null; then
        log "Project $PROJECT_ID already exists, selecting it..."
    else
        log "Creating new project: $PROJECT_ID"
        gcloud projects create "$PROJECT_ID" --name="Mammon Protocol" || {
            log_warn "Could not create project (may need org permissions)"
            log "Attempting to use existing project..."
        }
    fi

    gcloud config set project "$PROJECT_ID"
    log "Project set to: $PROJECT_ID"
}

enable_apis() {
    log "Enabling required GCP APIs..."

    gcloud services enable compute.googleapis.com --project="$PROJECT_ID" || {
        log_warn "Could not enable Compute API. You may need to link a billing account."
        log "Visit: https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
        read -p "Press Enter after linking billing account..."
        gcloud services enable compute.googleapis.com --project="$PROJECT_ID"
    }

    log "Compute Engine API enabled"
}

create_firewall_rules() {
    log "Creating firewall rules for Mammon ports..."

    # P2P port (28080)
    if gcloud compute firewall-rules describe mammon-p2p --project="$PROJECT_ID" &>/dev/null; then
        log "Firewall rule mammon-p2p already exists"
    else
        gcloud compute firewall-rules create mammon-p2p \
            --project="$PROJECT_ID" \
            --direction=INGRESS \
            --priority=1000 \
            --network=default \
            --action=ALLOW \
            --rules=tcp:28080 \
            --source-ranges=0.0.0.0/0 \
            --target-tags=mammon-node \
            --description="Mammon Protocol P2P port"
        log "Created firewall rule: mammon-p2p (TCP 28080)"
    fi

    # RPC port (28081)
    if gcloud compute firewall-rules describe mammon-rpc --project="$PROJECT_ID" &>/dev/null; then
        log "Firewall rule mammon-rpc already exists"
    else
        gcloud compute firewall-rules create mammon-rpc \
            --project="$PROJECT_ID" \
            --direction=INGRESS \
            --priority=1000 \
            --network=default \
            --action=ALLOW \
            --rules=tcp:28081 \
            --source-ranges=0.0.0.0/0 \
            --target-tags=mammon-node \
            --description="Mammon Protocol RPC port"
        log "Created firewall rule: mammon-rpc (TCP 28081)"
    fi

    # SSH (for management)
    if ! gcloud compute firewall-rules describe default-allow-ssh --project="$PROJECT_ID" &>/dev/null; then
        gcloud compute firewall-rules create allow-ssh \
            --project="$PROJECT_ID" \
            --direction=INGRESS \
            --priority=1000 \
            --network=default \
            --action=ALLOW \
            --rules=tcp:22 \
            --source-ranges=0.0.0.0/0 \
            --description="Allow SSH"
        log "Created firewall rule: allow-ssh"
    fi

    log "Firewall rules configured"
}

create_vm() {
    log "Creating Compute Engine VM: $VM_NAME"

    # Check if VM exists
    if gcloud compute instances describe "$VM_NAME" --zone="$ZONE" --project="$PROJECT_ID" &>/dev/null; then
        log_warn "VM $VM_NAME already exists in zone $ZONE"
        read -p "Delete and recreate? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            gcloud compute instances delete "$VM_NAME" \
                --zone="$ZONE" \
                --project="$PROJECT_ID" \
                --quiet
        else
            log "Keeping existing VM"
            return
        fi
    fi

    # Create startup script to be run on first boot
    STARTUP_SCRIPT='#!/bin/bash
    apt-get update
    apt-get install -y git screen htop
    echo "Mammon Protocol VM initialized" > /var/log/mammon-init.log
    '

    gcloud compute instances create "$VM_NAME" \
        --project="$PROJECT_ID" \
        --zone="$ZONE" \
        --machine-type="$MACHINE_TYPE" \
        --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
        --maintenance-policy=MIGRATE \
        --provisioning-model=STANDARD \
        --tags=mammon-node,http-server \
        --create-disk=auto-delete=yes,boot=yes,device-name="$VM_NAME",image=projects/$IMAGE_PROJECT/global/images/family/$IMAGE_FAMILY,mode=rw,size=$BOOT_DISK_SIZE,type=pd-ssd \
        --no-shielded-secure-boot \
        --shielded-vtpm \
        --shielded-integrity-monitoring \
        --labels=purpose=mammon-testnet \
        --metadata=startup-script="$STARTUP_SCRIPT"

    log "VM created successfully!"

    # Wait for VM to be ready
    log "Waiting for VM to be ready..."
    sleep 30
}

get_vm_ip() {
    EXTERNAL_IP=$(gcloud compute instances describe "$VM_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" \
        --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

    log "VM External IP: $EXTERNAL_IP"
    echo "$EXTERNAL_IP"
}

copy_patches_to_vm() {
    log "Copying Mammon patches to VM..."

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_DIR="$(dirname "$SCRIPT_DIR")"

    # Create tarball of patches and scripts
    cd "$REPO_DIR"
    tar -czf /tmp/mammon-patches.tar.gz patches/ src/ scripts/ config/ docs/

    # Copy to VM
    gcloud compute scp /tmp/mammon-patches.tar.gz "$VM_NAME":/tmp/ \
        --zone="$ZONE" \
        --project="$PROJECT_ID"

    # Extract on VM
    gcloud compute ssh "$VM_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" \
        --command="mkdir -p /tmp/mammon-patches && tar -xzf /tmp/mammon-patches.tar.gz -C /tmp/mammon-patches"

    log "Patches copied to VM at /tmp/mammon-patches/"
}

run_setup_on_vm() {
    log "Running Mammon setup script on VM..."
    log "This will take 20-30 minutes to build from source..."

    gcloud compute ssh "$VM_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" \
        --command="cd /tmp/mammon-patches && chmod +x scripts/vm_setup.sh && sudo bash scripts/vm_setup.sh"
}

print_summary() {
    EXTERNAL_IP=$(get_vm_ip)

    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}        MAMMON PROTOCOL DEPLOYMENT COMPLETE!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Project ID:    $PROJECT_ID"
    echo "VM Name:       $VM_NAME"
    echo "Zone:          $ZONE"
    echo "External IP:   $EXTERNAL_IP"
    echo ""
    echo "Ports open:"
    echo "  - 28080 (P2P)"
    echo "  - 28081 (RPC)"
    echo "  - 22 (SSH)"
    echo ""
    echo "Connect to VM:"
    echo "  gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID"
    echo ""
    echo "Test RPC:"
    echo "  curl http://$EXTERNAL_IP:28081/json_rpc -d '{\"method\":\"get_info\"}'"
    echo ""
    echo "Monitor node:"
    echo "  ssh to VM, then: screen -r mammon"
    echo ""
    echo -e "${CYAN}\"The devil you can audit\"${NC}"
    echo ""
}

# Main execution
main() {
    banner

    check_gcloud
    create_project
    enable_apis
    create_firewall_rules
    create_vm
    copy_patches_to_vm

    echo ""
    log "VM is ready. To build and run Mammon:"
    log "  1. SSH to VM: gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID"
    log "  2. Run setup: cd /tmp/mammon-patches && sudo bash scripts/vm_setup.sh"
    echo ""

    read -p "Run setup script on VM now? (y/N): " run_setup
    if [[ "$run_setup" =~ ^[Yy]$ ]]; then
        run_setup_on_vm
    fi

    print_summary
}

main "$@"
