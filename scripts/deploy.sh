#!/bin/bash

# Salesforce Conversational Report Builder - Deployment Script
# This script helps deploy the Salesforce components and set up the AI service

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if sf CLI is installed
    if ! command -v sf &> /dev/null; then
        print_error "Salesforce CLI (sf) is not installed. Please install it first."
        print_status "Visit: https://developer.salesforce.com/tools/sfdxcli"
        exit 1
    fi
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        print_warning "Node.js is not installed. The external AI service will not be set up."
        NODE_AVAILABLE=false
    else
        NODE_AVAILABLE=true
        NODE_VERSION=$(node --version)
        print_success "Node.js $NODE_VERSION found"
    fi
    
    # Check if npm is installed
    if ! command -v npm &> /dev/null; then
        print_warning "npm is not installed. The external AI service will not be set up."
        NPM_AVAILABLE=false
    else
        NPM_AVAILABLE=true
        NPM_VERSION=$(npm --version)
        print_success "npm $NPM_VERSION found"
    fi
    
    print_success "Prerequisites check completed"
}

# Function to check and set default org
check_salesforce_org() {
    print_status "Checking Salesforce org configuration..."
    
    # Check if default org is set
    if sf config get target-org | grep -q "No default org set"; then
        print_warning "No default org set. Please set your default org first:"
        print_status "sf config set target-org your-org-alias"
        print_status "Or run: sf org login web --set-default-dev-hub"
        exit 1
    fi
    
    # Get current default org
    DEFAULT_ORG=$(sf config get target-org | head -1)
    print_success "Using default org: $DEFAULT_ORG"
    
    # Verify org is accessible
    if sf org display --json | grep -q "error"; then
        print_error "Cannot access default org. Please check your authentication:"
        print_status "sf org login web --set-default-dev-hub"
        exit 1
    fi
    
    print_success "Default org is accessible and ready for deployment"
}

# Function to deploy Salesforce components
deploy_salesforce() {
    print_status "Deploying Salesforce components..."
    
    # Deploy custom object first
    print_status "Deploying QueryHistory__c custom object..."
    sf project deploy start --source-dir force-app/main/default/objects/QueryHistory__c
    
    # Deploy Apex classes
    print_status "Deploying Apex classes..."
    sf project deploy start --source-dir force-app/main/default/classes
    
    # Deploy LWC component
    print_status "Deploying Lightning Web Component..."
    sf project deploy start --source-dir force-app/main/default/lwc
    
    print_success "Salesforce components deployed successfully"
}

# Function to setup external AI service
setup_ai_service() {
    if [ "$NODE_AVAILABLE" = false ] || [ "$NPM_AVAILABLE" = false ]; then
        print_warning "Skipping AI service setup due to missing Node.js/npm"
        return
    fi
    
    print_status "Setting up external AI service..."
    
    cd external-ai-service
    
    # Install dependencies
    print_status "Installing Node.js dependencies..."
    npm install
    
    # Create environment file
    if [ ! -f .env ]; then
        print_status "Creating environment configuration file..."
        cat > .env << EOF
# AI Report Builder Service Configuration

# Server Configuration
PORT=3000
NODE_ENV=development

# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-4
OPENAI_TIMEOUT=30000

# Security Configuration
ALLOWED_ORIGINS=http://localhost:3000,https://your-salesforce-instance.com
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Salesforce Configuration
SALESFORCE_INSTANCE_URL=https://your-instance.salesforce.com
SALESFORCE_API_VERSION=v60.0

# Logging Configuration
LOG_LEVEL=info
LOG_FORMAT=combined

# Performance Configuration
REQUEST_TIMEOUT=30000
MAX_QUERY_LENGTH=1000
MAX_RESULTS_LIMIT=2000
EOF
        print_warning "Please edit .env file with your actual configuration values"
    else
        print_success "Environment configuration file already exists"
    fi
    
    cd ..
    print_success "External AI service setup completed"
}

# Function to display post-deployment instructions
show_instructions() {
    print_success "Deployment completed successfully!"
    echo
    echo "Next steps:"
    echo "==========="
    echo
    echo "1. Configure Named Credentials in Salesforce:"
    echo "   - Go to Setup > Named Credentials"
    echo "   - Create new credential named 'AI_Service'"
    echo "   - Set URL to your AI service endpoint"
    echo "   - Set Identity Type to 'Named Principal'"
    echo "   - Set Authentication Protocol to 'Password Authentication'"
    echo
    echo "2. Create Permission Set:"
    echo "   - Go to Setup > Permission Sets"
    echo "   - Create new permission set for AI Report Builder"
    echo "   - Assign access to AIReportService Apex class"
    echo "   - Assign access to QueryHistory__c custom object"
    echo "   - Assign access to standard objects (Account, Contact, Lead, Opportunity, Case)"
    echo
    echo "3. Assign Permission Set to Users:"
    echo "   - Go to Setup > Permission Sets"
    echo "   - Find your AI Report Builder permission set"
    echo "   - Click 'Manage Assignments'"
    echo "   - Add users who should have access"
    echo
    if [ "$NODE_AVAILABLE" = true ] && [ "$NPM_AVAILABLE" = true ]; then
        echo "4. Start AI Service:"
        echo "   cd external-ai-service"
        echo "   npm start"
        echo
        echo "5. Test the service:"
        echo "   curl -X POST http://localhost:3000/api/parse-query \\"
        echo "     -H 'Content-Type: application/json' \\"
        echo "     -d '{\"query\": \"Show me accounts\"}'"
        echo
    fi
    echo "6. Add AI Report Builder to your Salesforce pages:"
    echo "   - Go to Setup > Lightning App Builder"
    echo "   - Edit your desired page"
    echo "   - Search for 'AI Report Builder' component"
    echo "   - Add it to your page layout"
    echo
    echo "For more information, see the README.md file"
}

# Function to show setup instructions
show_setup_instructions() {
    echo
    echo "🔧 Setup Instructions:"
    echo "====================="
    echo
    echo "Before running this script, ensure you have:"
    echo "1. Salesforce CLI (sf) installed and authenticated"
    echo "2. Default org set: sf org login web --set-default-dev-hub"
    echo "3. Or set specific org: sf config set target-org your-org-alias"
    echo
    echo "To set your default org, run:"
    echo "sf org login web --set-default-dev-hub"
    echo
}

# Main execution
main() {
    echo "🚀 Salesforce Conversational Report Builder - Deployment Script"
    echo "================================================================"
    echo
    
    show_setup_instructions
    check_prerequisites
    check_salesforce_org
    deploy_salesforce
    setup_ai_service
    show_instructions
}

# Run main function
main "$@"
