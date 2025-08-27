# Salesforce Conversational Report Builder

## Project Overview
A conversational AI report builder for Salesforce that converts natural language queries into SOQL queries and generates actual Salesforce reports. Users can type requests like "Show me contacts with birthdays next month" or "Find accounts with AUM over 400k" and get back properly formatted reports.

## 🚀 Features

### Core Functionality
- **Natural Language Processing**: Convert conversational queries to SOQL
- **AI-Powered Query Generation**: OpenAI GPT-4 integration for intelligent parsing
- **Real-time Report Creation**: Generate and save Salesforce reports
- **Chat-like Interface**: Intuitive conversation flow with message history
- **Query History & Analytics**: Track and analyze user interactions

### Security & Compliance
- **Field-Level Security**: Respects Salesforce permissions and sharing rules
- **SOQL Injection Prevention**: Comprehensive input validation and sanitization
- **Audit Trail**: Complete logging of all queries and results
- **Governor Limit Management**: Optimized for Salesforce platform constraints

### User Experience
- **Lightning Web Component**: Modern, responsive Salesforce UI
- **SLDS Compliance**: Strict adherence to Salesforce Lightning Design System
- **Accessibility**: WCAG 2.1 AA compliant interface
- **Mobile Responsive**: Works across all device types

## 🏗️ Architecture

### Frontend
- **Lightning Web Component (LWC)**: `aiReportBuilder` component
- **SLDS Styling**: No custom CSS, pure Salesforce design system
- **Real-time Updates**: Reactive data binding and state management

### Backend
- **Apex REST Service**: `AIReportService` as bridge to external AI
- **SOQL Validation**: `SOQLValidator` for security and syntax checking
- **Report Generation**: `ReportGenerator` for creating Salesforce reports
- **Query History**: `QueryHistory` for tracking and analytics

### External AI Service
- **Node.js Express Server**: RESTful API endpoints
- **OpenAI Integration**: GPT-4 for natural language processing
- **SOQL Builder**: Intelligent query generation
- **Salesforce Mapping**: Business term to API field mapping

## 📁 Project Structure

```
force-app/main/default/
├── lwc/aiReportBuilder/           # Main LWC component
│   ├── aiReportBuilder.html      # SLDS-compliant template
│   ├── aiReportBuilder.js        # Component logic
│   └── aiReportBuilder.js-meta.xml
├── classes/                       # Apex classes
│   ├── AIReportService.cls       # Main REST service
│   ├── SOQLValidator.cls         # Query validation
│   ├── ReportGenerator.cls       # Report creation
│   └── QueryHistory.cls          # History tracking
└── objects/QueryHistory__c/      # Custom object for tracking

external-ai-service/               # Node.js AI service
├── server.js                     # Express server
├── routes/parseQuery.js          # API endpoints
├── services/openaiService.js     # OpenAI integration
├── utils/soqlBuilder.js          # SOQL generation
└── config/salesforceMapping.js   # Object/field mappings
```

## 🛠️ Installation & Setup

### Prerequisites
- Salesforce CLI (sf)
- Node.js 18.0.0+
- OpenAI API key
- Salesforce org with appropriate permissions

### 1. Deploy Salesforce Components

```bash
# Authenticate to your org
sf org login web

# Deploy the components
sf project deploy start

# Or deploy specific components
sf project deploy start --source-dir force-app/main/default/classes
sf project deploy start --source-dir force-app/main/default/lwc
sf project deploy start --source-dir force-app/main/default/objects
```

### 2. Setup External AI Service

```bash
cd external-ai-service

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your OpenAI API key and other settings

# Start the service
npm run dev
```

### 3. Configure Named Credentials

In Salesforce Setup, create a Named Credential:
- **Label**: AI_Service
- **Name**: AI_Service
- **URL**: Your AI service endpoint (e.g., `https://your-service.herokuapp.com`)
- **Identity Type**: Named Principal
- **Authentication Protocol**: Password Authentication

### 4. Assign Permissions

Create a Permission Set with:
- Access to `AIReportService` Apex class
- Access to `QueryHistory__c` custom object
- Access to standard objects (Account, Contact, Lead, Opportunity, Case)

## 🔧 Configuration

### Environment Variables

```env
# OpenAI Configuration
OPENAI_API_KEY=your_api_key_here
OPENAI_MODEL=gpt-4

# Salesforce Configuration
SALESFORCE_INSTANCE_URL=https://your-instance.salesforce.com
SALESFORCE_API_VERSION=v60.0

# Security
ALLOWED_ORIGINS=https://your-instance.salesforce.com
RATE_LIMIT_MAX_REQUESTS=100
```

### Custom Settings

The system automatically detects available Salesforce objects and fields. Custom fields are supported with the `__c` suffix.

## 📖 Usage Examples

### Basic Queries
```
"Show me all accounts"
"Find contacts created this month"
"List opportunities with high value"
"Cases that are still open"
```

### Advanced Queries
```
"Show me accounts in the technology industry with revenue over 1M"
"Find contacts with birthdays next month who are VIP customers"
"List opportunities closing this quarter with probability over 80%"
"Cases escalated in the last 7 days with high priority"
```

### Business Term Recognition
The AI automatically maps business terms:
- "customers" → Account
- "deals" → Opportunity
- "leads" → Lead
- "support tickets" → Case
- "high revenue" → Amount > 100,000
- "this month" → CreatedDate = THIS_MONTH

## 🔒 Security Features

### Input Validation
- Query length limits (1000 characters)
- SOQL injection prevention
- Malicious keyword detection
- Field and object permission validation

### Data Access
- Respects field-level security
- Enforces sharing rules
- User permission validation
- Audit logging of all queries

### API Security
- Rate limiting (100 requests/15 min)
- CORS configuration
- Request size limits
- Authentication headers

## 📊 Monitoring & Analytics

### Query History
- Tracks all user queries
- Records generated SOQL
- Measures execution time
- Success/failure tracking

### Analytics Dashboard
- Total queries executed
- Success rate metrics
- Most common queries
- Performance trends

### Health Monitoring
- Service availability checks
- OpenAI API status
- Response time monitoring
- Error rate tracking

## 🚀 Deployment

### Salesforce Deployment
```bash
# Validate deployment
sf project deploy validate

# Deploy to sandbox
sf project deploy start --target-org your-sandbox

# Deploy to production
sf project deploy start --target-org your-production
```

### AI Service Deployment

#### Heroku
```bash
heroku create your-ai-service
heroku config:set OPENAI_API_KEY=your_key
git push heroku main
```

#### AWS
```bash
# Deploy using AWS CLI or CloudFormation
aws deploy create-deployment --application-name ai-report-builder
```

#### Docker
```bash
docker build -t ai-report-builder .
docker run -p 3000:3000 ai-report-builder
```

## 🧪 Testing

### Apex Tests
```bash
# Run all tests
sf apex run test

# Run specific test class
sf apex run test --class-names AIReportServiceTest
```

### LWC Tests
```bash
# Run Jest tests
npm test

# Run with coverage
npm run test:coverage
```

### Integration Tests
```bash
# Test AI service endpoints
curl -X POST https://your-service.herokuapp.com/api/parse-query \
  -H "Content-Type: application/json" \
  -d '{"query": "Show me accounts"}'
```

## 🔍 Troubleshooting

### Common Issues

1. **OpenAI API Errors**
   - Verify API key validity
   - Check quota and billing
   - Ensure model availability

2. **Permission Errors**
   - Verify user permissions
   - Check field-level security
   - Validate object access

3. **SOQL Generation Failures**
   - Review query complexity
   - Check field existence
   - Validate object relationships

### Debug Mode
Enable debug logging in Salesforce:
```apex
System.debug(LoggingLevel.INFO, 'Debug message');
```

Enable debug logging in AI service:
```env
LOG_LEVEL=debug
NODE_ENV=development
```

## 📈 Performance Optimization

### Salesforce Optimizations
- Query result caching
- Governor limit monitoring
- Bulk query processing
- Field selection optimization

### AI Service Optimizations
- Request batching
- Response caching
- Connection pooling
- Load balancing

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Follow coding standards:
   - Apex: Salesforce Style Guide
   - LWC: Lightning Web Components Guide
   - Node.js: Standard JavaScript practices
4. Add comprehensive tests
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.

## 🆘 Support

- **Documentation**: Check this README and inline code comments
- **Issues**: Create GitHub issues for bugs or feature requests
- **Community**: Salesforce Developer Community forums
- **Contact**: Reach out to the development team

## 🗺️ Roadmap

### Phase 2 (Next Release)
- Multi-object relationship queries
- Advanced date handling
- Custom field discovery
- Query result caching

### Phase 3 (Future)
- Natural language report customization
- Scheduled report generation
- Advanced analytics dashboard
- Mobile app integration

---

**Built with ❤️ for the Salesforce community**

*This project follows all Salesforce development best practices and security guidelines.*
