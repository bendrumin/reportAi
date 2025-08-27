# Salesforce AI Report Builder - External Service

## Overview
This is the external AI service component of the Salesforce Conversational Report Builder. It processes natural language queries and generates SOQL queries using OpenAI's GPT-4 model.

## Features
- Natural language processing with OpenAI GPT-4
- SOQL query generation and validation
- Salesforce object and field mapping
- Business term recognition
- RESTful API endpoints
- Security and rate limiting
- Comprehensive error handling

## Prerequisites
- Node.js 18.0.0 or higher
- npm 8.0.0 or higher
- OpenAI API key
- Salesforce instance access

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd external-ai-service
```

2. Install dependencies:
```bash
npm install
```

3. Create environment configuration:
```bash
cp .env.example .env
```

4. Configure environment variables in `.env`:
```env
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
```

## Usage

### Development Mode
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

### Testing
```bash
npm test
```

### Linting
```bash
npm run lint
```

### Code Formatting
```bash
npm run format
```

## API Endpoints

### POST /api/parse-query
Processes natural language queries and generates SOQL.

**Request Body:**
```json
{
  "query": "Show me accounts with high revenue",
  "userId": "user123",
  "orgId": "org456"
}
```

**Response:**
```json
{
  "success": true,
  "soqlQuery": "SELECT Id, Name, Industry, AnnualRevenue FROM Account WHERE AnnualRevenue > 1000000 AND IsDeleted = false LIMIT 1000",
  "explanation": "Generated SOQL query for accounts with high revenue",
  "fields": ["Id", "Name", "Industry", "AnnualRevenue"],
  "metadata": {
    "originalQuery": "Show me accounts with high revenue",
    "userId": "user123",
    "orgId": "org456",
    "timestamp": "2025-08-26T10:00:00.000Z",
    "processingTime": 1500
  }
}
```

### GET /api/salesforce-schema
Returns available Salesforce objects and fields.

### GET /health
Health check endpoint.

## Architecture

### Services
- **OpenAI Service**: Handles AI processing and natural language understanding
- **SOQL Builder**: Converts AI responses to valid SOQL queries
- **Salesforce Mapping**: Manages object and field mappings

### Utilities
- **Query Validation**: Ensures SOQL syntax and security
- **Business Term Mapping**: Converts business language to Salesforce terms
- **Error Handling**: Comprehensive error management and logging

## Security Features

- Input validation and sanitization
- Rate limiting (100 requests per 15 minutes)
- CORS configuration
- Helmet security headers
- Request size limits
- SOQL injection prevention

## Error Handling

The service provides detailed error responses with appropriate HTTP status codes:

- **400**: Bad Request (invalid input)
- **429**: Too Many Requests (rate limit exceeded)
- **500**: Internal Server Error (processing failures)

## Performance

- Request timeout: 30 seconds
- Maximum query length: 1000 characters
- Maximum results: 2000 records
- OpenAI timeout: 25 seconds

## Deployment

### Heroku
```bash
heroku create your-app-name
heroku config:set OPENAI_API_KEY=your_key
git push heroku main
```

### AWS
```bash
# Deploy using AWS CLI or CloudFormation
aws deploy create-deployment --application-name your-app
```

### Docker
```bash
docker build -t ai-report-builder .
docker run -p 3000:3000 ai-report-builder
```

## Monitoring

### Health Checks
- Service health endpoint: `/health`
- OpenAI service status
- Request processing metrics

### Logging
- Request/response logging
- Error tracking
- Performance metrics
- OpenAI API usage

## Troubleshooting

### Common Issues

1. **OpenAI API Errors**
   - Verify API key is valid
   - Check API quota and billing
   - Ensure model availability

2. **Rate Limiting**
   - Adjust rate limit configuration
   - Implement client-side retry logic
   - Monitor usage patterns

3. **SOQL Generation Failures**
   - Check Salesforce object permissions
   - Validate field accessibility
   - Review query complexity limits

### Debug Mode
Enable debug logging by setting:
```env
LOG_LEVEL=debug
NODE_ENV=development
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## Changelog

### Version 1.0.0
- Initial release
- OpenAI GPT-4 integration
- SOQL generation and validation
- Salesforce object mapping
- RESTful API endpoints
- Security and performance features
