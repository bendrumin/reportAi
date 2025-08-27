/**
 * @description Service class for AI-powered report generation
 * @author Ben Siegel
 * @date 2025-08-26
 * @group AI Services
 * @version 1.0
 */
@RestResource(urlMapping='/AIReportService/*')
global with sharing class AIReportService {
    
    // Constants - UPPER_SNAKE_CASE
    private static final Integer MAX_QUERY_LIMIT = 2000;
    private static final String AI_SERVICE_NAMED_CREDENTIAL = 'AI_Service';
    private static final Set<String> ALLOWED_OBJECTS = new Set<String>{
        'Account', 'Contact', 'Lead', 'Opportunity', 'Case', 'Task', 'Event'
    };
    private static final Integer REQUEST_TIMEOUT = 30000; // 30 seconds
    
    /**
     * @description Processes natural language query and returns formatted results
     * @param none - Uses RestContext.request for input
     * @return AIReportResponse containing query results and metadata
     * @throws AIServiceException for processing errors
     * @example 
     * POST /services/apexrest/AIReportService/
     * Body: {"query": "Show me accounts with AUM over 400k"}
     */
    @HttpPost
    global static AIReportResponse processQuery() {
        String methodName = 'processQuery';
        System.debug(LoggingLevel.INFO, methodName + ' - Entry');
        
        try {
            // Input validation
            validateRequest();
            
            // Process query with bulkification
            return processQueryInternal();
            
        } catch (AIServiceException e) {
            System.debug(LoggingLevel.ERROR, methodName + ' - AIServiceException: ' + e.getMessage());
            throw e;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, methodName + ' - Unexpected error: ' + e.getMessage());
            throw new AIServiceException('Query processing failed: ' + e.getMessage());
        }
    }
    
    /**
     * @description Internal query processing with governor limit management
     * @return AIReportResponse processed query results
     */
    private static AIReportResponse processQueryInternal() {
        String methodName = 'processQueryInternal';
        System.debug(LoggingLevel.INFO, methodName + ' - Entry');
        
        // Parse request body
        String requestBody = RestContext.request.requestBody.toString();
        Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        
        String userQuery = (String) requestMap.get('query');
        if (String.isBlank(userQuery)) {
            throw new AIServiceException('Query parameter is required');
        }
        
        // Sanitize user input
        String sanitizedQuery = sanitizeUserInput(userQuery);
        
        // Call external AI service
        AIQueryRequest aiRequest = new AIQueryRequest();
        aiRequest.query = sanitizedQuery;
        aiRequest.userId = UserInfo.getUserId();
        aiRequest.orgId = UserInfo.getOrganizationId();
        
        AIQueryResponse aiResponse = callExternalAIService(aiRequest);
        
        if (!aiResponse.success) {
            throw new AIServiceException('AI service error: ' + aiResponse.errorMessage);
        }
        
        // Validate generated SOQL
        String generatedSOQL = aiResponse.soqlQuery;
        SOQLValidator.validateQuery(generatedSOQL);
        
        // Execute query securely
        List<SObject> queryResults = executeQuerySecurely(generatedSOQL);
        
        // Build response
        AIReportResponse response = new AIReportResponse();
        response.soqlQuery = generatedSOQL;
        response.results = queryResults;
        response.explanation = aiResponse.explanation;
        response.recordCount = queryResults.size();
        response.success = true;
        
        // Log query for audit trail
        logQueryExecution(sanitizedQuery, generatedSOQL, response.recordCount);
        
        System.debug(LoggingLevel.INFO, methodName + ' - Exit: ' + response.recordCount + ' records returned');
        return response;
    }
    
    /**
     * @description Validates incoming REST request structure
     * @throws AIServiceException for invalid requests
     */
    private static void validateRequest() {
        if (RestContext.request == null || RestContext.request.requestBody == null) {
            throw new AIServiceException('Request body is required');
        }
        
        // Check request size limits
        if (RestContext.request.requestBody.size() > 1000000) { // 1MB limit
            throw new AIServiceException('Request body exceeds size limit');
        }
    }
    
    /**
     * @description Sanitizes user input to prevent injection attacks
     * @param input User input string
     * @return Sanitized input string
     * @throws IllegalArgumentException for invalid input
     */
    private static String sanitizeUserInput(String input) {
        if (String.isBlank(input)) {
            throw new IllegalArgumentException('Input cannot be blank');
        }
        
        // Remove potential SOQL injection characters
        String sanitized = input.replaceAll('[^a-zA-Z0-9\\s\\-\\.\\,\\?\\!]', '');
        
        if (sanitized.length() > 255) {
            throw new IllegalArgumentException('Input exceeds maximum length');
        }
        
        return sanitized.trim();
    }
    
    /**
     * @description Calls external AI service via named credential
     * @param request AI query request
     * @return AI query response
     */
    private static AIQueryResponse callExternalAIService(AIQueryRequest request) {
        String methodName = 'callExternalAIService';
        System.debug(LoggingLevel.INFO, methodName + ' - Entry');
        
        try {
            // Prepare HTTP request
            Http http = new Http();
            HttpRequest httpRequest = new HttpRequest();
            httpRequest.setEndpoint('callout:' + AI_SERVICE_NAMED_CREDENTIAL + '/api/parse-query');
            httpRequest.setMethod('POST');
            httpRequest.setHeader('Content-Type', 'application/json');
            httpRequest.setHeader('Authorization', 'Bearer ' + getAIServiceToken());
            httpRequest.setBody(JSON.serialize(request));
            httpRequest.setTimeout(REQUEST_TIMEOUT);
            
            // Execute request
            HttpResponse response = http.send(httpRequest);
            
            if (response.getStatusCode() != 200) {
                throw new AIServiceException('AI service returned status: ' + response.getStatusCode());
            }
            
            AIQueryResponse aiResponse = (AIQueryResponse) JSON.deserialize(
                response.getBody(), 
                AIQueryResponse.class
            );
            
            System.debug(LoggingLevel.INFO, methodName + ' - Exit: AI service call successful');
            return aiResponse;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, methodName + ' - Error calling AI service: ' + e.getMessage());
            throw new AIServiceException('Failed to communicate with AI service: ' + e.getMessage());
        }
    }
    
    /**
     * @description Executes SOQL query with security and permission checks
     * @param soqlQuery SOQL query to execute
     * @return List of SObject results
     */
    private static List<SObject> executeQuerySecurely(String soqlQuery) {
        String methodName = 'executeQuerySecurely';
        System.debug(LoggingLevel.INFO, methodName + ' - Entry');
        
        try {
            // Execute query
            List<SObject> results = Database.query(soqlQuery);
            
            // Apply field-level security
            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.READABLE,
                results
            );
            
            List<SObject> secureResults = decision.getRecords();
            
            System.debug(LoggingLevel.INFO, methodName + ' - Exit: ' + secureResults.size() + ' secure records returned');
            return secureResults;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, methodName + ' - Query execution error: ' + e.getMessage());
            throw new AIServiceException('Query execution failed: ' + e.getMessage());
        }
    }
    
    /**
     * @description Logs query execution for audit purposes
     * @param userQuery Original user query
     * @param generatedSOQL Generated SOQL query
     * @param recordCount Number of records returned
     */
    private static void logQueryExecution(String userQuery, String generatedSOQL, Integer recordCount) {
        try {
            QueryHistory__c history = new QueryHistory__c(
                User_Query__c = userQuery,
                Generated_SOQL__c = generatedSOQL,
                Record_Count__c = recordCount,
                User__c = UserInfo.getUserId(),
                Execution_Time__c = System.now()
            );
            
            insert history;
            
        } catch (Exception e) {
            // Log error but don't fail the main operation
            System.debug(LoggingLevel.ERROR, 'Failed to log query history: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets AI service authentication token
     * @return Authentication token string
     */
    private static String getAIServiceToken() {
        // In production, this would use a more secure token management system
        // For now, returning a placeholder - implement based on your auth strategy
        return 'placeholder-token';
    }
}

/**
 * @description Request wrapper for AI service calls
 */
global class AIQueryRequest {
    @AuraEnabled global String query { get; set; }
    @AuraEnabled global String userId { get; set; }
    @AuraEnabled global String orgId { get; set; }
}

/**
 * @description Response wrapper from AI service
 */
global class AIQueryResponse {
    @AuraEnabled global String soqlQuery { get; set; }
    @AuraEnabled global String explanation { get; set; }
    @AuraEnabled global List<String> fields { get; set; }
    @AuraEnabled global Boolean success { get; set; }
    @AuraEnabled global String errorMessage { get; set; }
    
    global AIQueryResponse() {
        this.success = true;
        this.fields = new List<String>();
    }
}

/**
 * @description Response wrapper for AI service calls
 */
global class AIReportResponse {
    @AuraEnabled global String soqlQuery { get; set; }
    @AuraEnabled global List<SObject> results { get; set; }
    @AuraEnabled global String explanation { get; set; }
    @AuraEnabled global Integer recordCount { get; set; }
    @AuraEnabled global Boolean success { get; set; }
    @AuraEnabled global String errorMessage { get; set; }
    
    global AIReportResponse() {
        this.success = true;
        this.results = new List<SObject>();
        this.recordCount = 0;
    }
}

/**
 * @description Custom exception for AI service errors
 */
global class AIServiceException extends Exception {}
