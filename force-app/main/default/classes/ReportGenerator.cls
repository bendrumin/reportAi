/**
 * @description Generates Salesforce reports from AI query results
 * @author Ben Siegel
 * @date 2025-08-26
 * @group AI Services
 * @version 1.0
 */
global with sharing class ReportGenerator {
    
    // Constants - UPPER_SNAKE_CASE
    private static final String DEFAULT_REPORT_FOLDER = 'AI Generated Reports';
    private static final Integer MAX_REPORT_NAME_LENGTH = 80;
    private static final String REPORT_NAME_PREFIX = 'AI Report - ';
    
    /**
     * @description Creates a Salesforce report from query results
     * @param reportName Name for the new report
     * @param objectType SObject type for the report
     * @param fields List of fields to include in report
     * @param filters List of filter criteria
     * @return Report ID of the created report
     * @throws ReportGenerationException for creation failures
     */
    global static Id createReport(String reportName, String objectType, List<String> fields, List<ReportFilter> filters) {
        String methodName = 'createReport';
        System.debug(LoggingLevel.INFO, methodName + ' - Entry');
        
        try {
            // Validate inputs
            validateReportInputs(reportName, objectType, fields);
            
            // Ensure report folder exists
            Id folderId = ensureReportFolderExists();
            
            // Create report metadata
            Report report = createReportMetadata(reportName, objectType, fields, filters, folderId);
            
            // Insert report
            insert report;
            
            System.debug(LoggingLevel.INFO, methodName + ' - Exit: Report created with ID ' + report.Id);
            return report.Id;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, methodName + ' - Error creating report: ' + e.getMessage());
            throw new ReportGenerationException('Failed to create report: ' + e.getMessage());
        }
    }
    
    /**
     * @description Creates a tabular report from SOQL query results
     * @param reportName Name for the new report
     * @param queryResults List of SObject results
     * @param soqlQuery Original SOQL query for reference
     * @return Report ID of the created report
     */
    global static Id createReportFromResults(String reportName, List<SObject> queryResults, String soqlQuery) {
        String methodName = 'createReportFromResults';
        System.debug(LoggingLevel.INFO, methodName + ' - Entry');
        
        try {
            if (queryResults == null || queryResults.isEmpty()) {
                throw new ReportGenerationException('No query results to create report from');
            }
            
            // Extract object type and fields from results
            String objectType = queryResults[0].getSObjectType().getDescribe().getName();
            List<String> fields = extractFieldsFromResults(queryResults);
            
            // Create filters from SOQL query
            List<ReportFilter> filters = extractFiltersFromSOQL(soqlQuery);
            
            // Create the report
            return createReport(reportName, objectType, fields, filters);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, methodName + ' - Error creating report from results: ' + e.getMessage());
            throw new ReportGenerationException('Failed to create report from results: ' + e.getMessage());
        }
    }
    
    /**
     * @description Validates report creation inputs
     * @param reportName Name for the report
     * @param objectType SObject type
     * @param fields List of fields
     * @throws IllegalArgumentException for invalid inputs
     */
    private static void validateReportInputs(String reportName, String objectType, List<String> fields) {
        if (String.isBlank(reportName)) {
            throw new IllegalArgumentException('Report name cannot be blank');
        }
        
        if (reportName.length() > MAX_REPORT_NAME_LENGTH) {
            throw new IllegalArgumentException('Report name exceeds maximum length of ' + MAX_REPORT_NAME_LENGTH);
        }
        
        if (String.isBlank(objectType)) {
            throw new IllegalArgumentException('Object type cannot be blank');
        }
        
        if (fields == null || fields.isEmpty()) {
            throw new IllegalArgumentException('At least one field must be specified');
        }
        
        // Validate object type exists and is accessible
        if (!isObjectAccessible(objectType)) {
            throw new IllegalArgumentException('Object type not accessible: ' + objectType);
        }
    }
    
    /**
     * @description Ensures the AI reports folder exists
     * @return Folder ID for AI reports
     */
    private static Id ensureReportFolderExists() {
        try {
            // Check if folder already exists
            List<Report> existingFolders = [
                SELECT Id, Name 
                FROM Report 
                WHERE Name = :DEFAULT_REPORT_FOLDER 
                LIMIT 1
            ];
            
            if (!existingFolders.isEmpty()) {
                return existingFolders[0].Id;
            }
            
            // Create new folder (this is a simplified approach)
            // In production, you'd use proper folder creation APIs
            return UserInfo.getUserId(); // Use user's personal folder for now
            
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Could not create report folder: ' + e.getMessage());
            return UserInfo.getUserId(); // Fallback to user's personal folder
        }
    }
    
    /**
     * @description Creates report metadata object
     * @param reportName Name for the report
     * @param objectType SObject type
     * @param fields List of fields
     * @param filters List of filters
     * @param folderId Folder ID
     * @return Report object
     */
    private static Report createReportMetadata(String reportName, String objectType, List<String> fields, List<ReportFilter> filters, Id folderId) {
        Report report = new Report();
        report.Name = reportName;
        report.DeveloperName = generateDeveloperName(reportName);
        report.FolderId = folderId;
        
        // Set report type based on object
        report.ReportTypeId = getReportTypeId(objectType);
        
        // Additional metadata would be set here
        // Note: This is a simplified implementation
        // Full report creation requires more complex metadata
        
        return report;
    }
    
    /**
     * @description Generates a unique developer name for the report
     * @param reportName Display name of the report
     * @return Developer name string
     */
    private static String generateDeveloperName(String reportName) {
        String baseName = reportName.replaceAll('[^a-zA-Z0-9]', '_');
        String timestamp = String.valueOf(System.currentTimeMillis());
        return baseName + '_' + timestamp;
    }
    
    /**
     * @description Gets report type ID for specified object
     * @param objectType SObject type
     * @return Report type ID
     */
    private static Id getReportTypeId(String objectType) {
        try {
            // Query for report type
            List<ReportType> reportTypes = [
                SELECT Id, DeveloperName 
                FROM ReportType 
                WHERE DeveloperName LIKE :objectType + '%' 
                LIMIT 1
            ];
            
            if (!reportTypes.isEmpty()) {
                return reportTypes[0].Id;
            }
            
            // Fallback to generic report type
            return null;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Could not find report type for ' + objectType + ': ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Extracts field names from query results
     * @param queryResults List of SObject results
     * @return List of field names
     */
    private static List<String> extractFieldsFromResults(List<SObject> queryResults) {
        List<String> fields = new List<String>();
        
        if (queryResults.isEmpty()) {
            return fields;
        }
        
        // Get field map from first record
        Map<String, Object> fieldMap = queryResults[0].getPopulatedFieldsAsMap();
        fields.addAll(fieldMap.keySet());
        
        return fields;
    }
    
    /**
     * @description Extracts filter criteria from SOQL query
     * @param soqlQuery SOQL query string
     * @return List of report filters
     */
    private static List<ReportFilter> extractFiltersFromSOQL(String soqlQuery) {
        List<ReportFilter> filters = new List<ReportFilter>();
        
        if (String.isBlank(soqlQuery)) {
            return filters;
        }
        
        try {
            // Parse WHERE clause from SOQL
            String upperQuery = soqlQuery.toUpperCase();
            if (upperQuery.contains(' WHERE ')) {
                String whereClause = soqlQuery.substring(
                    soqlQuery.toUpperCase().indexOf(' WHERE ') + 7
                );
                
                // Extract individual conditions
                String[] conditions = whereClause.split(' AND | OR ');
                
                for (String condition : conditions) {
                    if (condition.contains('=') || condition.contains('>') || condition.contains('<')) {
                        ReportFilter filter = parseFilterCondition(condition.trim());
                        if (filter != null) {
                            filters.add(filter);
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Could not parse filters from SOQL: ' + e.getMessage());
        }
        
        return filters;
    }
    
    /**
     * @description Parses individual filter condition
     * @param condition Filter condition string
     * @return ReportFilter object
     */
    private static ReportFilter parseFilterCondition(String condition) {
        try {
            // Simple parsing - in production you'd want more robust parsing
            if (condition.contains('=')) {
                String[] parts = condition.split('=');
                if (parts.length == 2) {
                    ReportFilter filter = new ReportFilter();
                    filter.fieldName = parts[0].trim();
                    filter.operator = 'equals';
                    filter.value = parts[1].trim().replaceAll('[\'"]', '');
                    return filter;
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Could not parse filter condition: ' + condition);
        }
        
        return null;
    }
    
    /**
     * @description Checks if object is accessible
     * @param objectType SObject type
     * @return Boolean indicating access
     */
    private static Boolean isObjectAccessible(String objectType) {
        try {
            switch on objectType {
                when 'Account' {
                    return Schema.sObjectType.Account.isAccessible();
                }
                when 'Contact' {
                    return Schema.sObjectType.Contact.isAccessible();
                }
                when 'Lead' {
                    return Schema.sObjectType.Lead.isAccessible();
                }
                when 'Opportunity' {
                    return Schema.sObjectType.Opportunity.isAccessible();
                }
                when 'Case' {
                    return Schema.sObjectType.Case.isAccessible();
                }
                when 'Task' {
                    return Schema.sObjectType.Task.isAccessible();
                }
                when 'Event' {
                    return Schema.sObjectType.Event.isAccessible();
                }
                when else {
                    return false;
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error checking object access for ' + objectType + ': ' + e.getMessage());
            return false;
        }
    }
}

/**
 * @description Filter criteria for report generation
 */
global class ReportFilter {
    @AuraEnabled global String fieldName { get; set; }
    @AuraEnabled global String operator { get; set; }
    @AuraEnabled global String value { get; set; }
    
    global ReportFilter() {}
    
    global ReportFilter(String fieldName, String operator, String value) {
        this.fieldName = fieldName;
        this.operator = operator;
        this.value = value;
    }
}

/**
 * @description Custom exception for report generation errors
 */
global class ReportGenerationException extends Exception {}
