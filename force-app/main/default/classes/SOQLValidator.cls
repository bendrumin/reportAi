/**
 * @description Validates SOQL queries for security and syntax compliance
 * @author Ben Siegel
 * @date 2025-08-26
 * @group AI Services
 * @version 1.0
 */
global with sharing class SOQLValidator {
    
    // Constants - UPPER_SNAKE_CASE
    private static final Set<String> ALLOWED_OBJECTS = new Set<String>{
        'Account', 'Contact', 'Lead', 'Opportunity', 'Case', 'Task', 'Event'
    };
    
    private static final Set<String> FORBIDDEN_KEYWORDS = new Set<String>{
        'INSERT', 'UPDATE', 'DELETE', 'UPSERT', 'MERGE', 'UNDELETE',
        'CREATE', 'ALTER', 'DROP', 'EXECUTE', 'EXEC', 'CALL'
    };
    
    private static final Set<String> FORBIDDEN_FUNCTIONS = new Set<String>{
        'CALLOUT', 'FUTURE', 'BATCH', 'SCHEDULE', 'QUEUEABLE'
    };
    
    private static final Integer MAX_QUERY_LENGTH = 10000;
    private static final Integer MAX_WHERE_CLAUSES = 20;
    
    /**
     * @description Validates SOQL query for security and compliance
     * @param soqlQuery SOQL query string to validate
     * @throws SecurityException for security violations
     * @throws IllegalArgumentException for syntax violations
     */
    global static void validateQuery(String soqlQuery) {
        if (String.isBlank(soqlQuery)) {
            throw new IllegalArgumentException('SOQL query cannot be blank');
        }
        
        // Check query length
        if (soqlQuery.length() > MAX_QUERY_LENGTH) {
            throw new IllegalArgumentException('SOQL query exceeds maximum length of ' + MAX_QUERY_LENGTH);
        }
        
        // Convert to uppercase for keyword checking
        String upperQuery = soqlQuery.toUpperCase();
        
        // Check for forbidden keywords
        validateForbiddenKeywords(upperQuery);
        
        // Check for forbidden functions
        validateForbiddenFunctions(upperQuery);
        
        // Validate object access
        validateObjectAccess(soqlQuery);
        
        // Validate field access
        validateFieldAccess(soqlQuery);
        
        // Validate query structure
        validateQueryStructure(soqlQuery);
        
        // Validate LIMIT clause
        validateLimitClause(soqlQuery);
    }
    
    /**
     * @description Validates query doesn't contain forbidden keywords
     * @param upperQuery Uppercase version of SOQL query
     * @throws SecurityException for security violations
     */
    private static void validateForbiddenKeywords(String upperQuery) {
        for (String keyword : FORBIDDEN_KEYWORDS) {
            if (upperQuery.contains(keyword)) {
                throw new SecurityException('Forbidden keyword detected: ' + keyword);
            }
        }
    }
    
    /**
     * @description Validates query doesn't contain forbidden functions
     * @param upperQuery Uppercase version of SOQL query
     * @throws SecurityException for security violations
     */
    private static void validateForbiddenFunctions(String upperQuery) {
        for (String function : FORBIDDEN_FUNCTIONS) {
            if (upperQuery.contains(function)) {
                throw new SecurityException('Forbidden function detected: ' + function);
            }
        }
    }
    
    /**
     * @description Validates user has access to objects in query
     * @param soqlQuery SOQL query string
     * @throws SecurityException for permission violations
     */
    private static void validateObjectAccess(String soqlQuery) {
        // Extract object names from query
        Set<String> objectNames = extractObjectNames(soqlQuery);
        
        for (String objectName : objectNames) {
            if (!ALLOWED_OBJECTS.contains(objectName)) {
                throw new SecurityException('Access denied to object: ' + objectName);
            }
            
            // Check object-level permissions
            if (!isObjectAccessible(objectName)) {
                throw new SecurityException('Insufficient permissions for object: ' + objectName);
            }
        }
    }
    
    /**
     * @description Validates user has access to fields in query
     * @param soqlQuery SOQL query string
     * @throws SecurityException for permission violations
     */
    private static void validateFieldAccess(String soqlQuery) {
        // Extract field names from query
        Set<String> fieldNames = extractFieldNames(soqlQuery);
        
        for (String fieldName : fieldNames) {
            if (!isFieldAccessible(fieldName)) {
                throw new SecurityException('Insufficient permissions for field: ' + fieldName);
            }
        }
    }
    
    /**
     * @description Validates basic query structure and syntax
     * @param soqlQuery SOQL query string
     * @throws IllegalArgumentException for syntax violations
     */
    private static void validateQueryStructure(String soqlQuery) {
        // Check for basic SELECT statement
        if (!soqlQuery.toUpperCase().startsWith('SELECT ')) {
            throw new IllegalArgumentException('Query must start with SELECT statement');
        }
        
        // Check for FROM clause
        if (!soqlQuery.toUpperCase().contains(' FROM ')) {
            throw new IllegalArgumentException('Query must contain FROM clause');
        }
        
        // Check WHERE clause complexity
        validateWhereClauseComplexity(soqlQuery);
    }
    
    /**
     * @description Validates WHERE clause complexity
     * @param soqlQuery SOQL query string
     * @throws IllegalArgumentException for complexity violations
     */
    private static void validateWhereClauseComplexity(String soqlQuery) {
        String upperQuery = soqlQuery.toUpperCase();
        
        // Count WHERE clauses
        Integer whereCount = upperQuery.split(' WHERE ').size() - 1;
        if (whereCount > MAX_WHERE_CLAUSES) {
            throw new IllegalArgumentException('Query contains too many WHERE clauses: ' + whereCount);
        }
        
        // Check for nested queries (subqueries)
        Integer subqueryCount = upperQuery.split('SELECT ').size() - 1;
        if (subqueryCount > 1) {
            throw new IllegalArgumentException('Nested queries are not allowed');
        }
    }
    
    /**
     * @description Validates LIMIT clause for performance
     * @param soqlQuery SOQL query string
     * @throws IllegalArgumentException for limit violations
     */
    private static void validateLimitClause(String soqlQuery) {
        String upperQuery = soqlQuery.toUpperCase();
        
        if (upperQuery.contains(' LIMIT ')) {
            // Extract limit value
            Pattern limitPattern = Pattern.compile('LIMIT\\s+(\\d+)');
            Matcher matcher = limitPattern.matcher(upperQuery);
            
            if (matcher.find()) {
                Integer limitValue = Integer.valueOf(matcher.group(1));
                if (limitValue > 2000) {
                    throw new IllegalArgumentException('Query limit cannot exceed 2000 records');
                }
            }
        } else {
            // Add default limit for performance
            throw new IllegalArgumentException('Query must include LIMIT clause for performance');
        }
    }
    
    /**
     * @description Extracts object names from SOQL query
     * @param soqlQuery SOQL query string
     * @return Set of object names
     */
    private static Set<String> extractObjectNames(String soqlQuery) {
        Set<String> objectNames = new Set<String>();
        
        // Extract from FROM clause
        Pattern fromPattern = Pattern.compile('FROM\\s+([\\w\\.]+)', Pattern.CASE_INSENSITIVE);
        Matcher fromMatcher = fromPattern.matcher(soqlQuery);
        
        while (fromMatcher.find()) {
            String objectName = fromMatcher.group(1).split('\\.')[0];
            objectNames.add(objectName);
        }
        
        return objectNames;
    }
    
    /**
     * @description Extracts field names from SOQL query
     * @param soqlQuery SOQL query string
     * @return Set of field names
     */
    private static Set<String> extractFieldNames(String soqlQuery) {
        Set<String> fieldNames = new Set<String>();
        
        // Extract from SELECT clause
        Pattern selectPattern = Pattern.compile('SELECT\\s+(.+?)\\s+FROM', Pattern.CASE_INSENSITIVE);
        Matcher selectMatcher = selectPattern.matcher(soqlQuery);
        
        if (selectMatcher.find()) {
            String selectClause = selectMatcher.group(1);
            
            // Handle individual fields
            if (!selectClause.equalsIgnoreCase('*')) {
                String[] fields = selectClause.split(',');
                for (String field : fields) {
                    String cleanField = field.trim().split('\\.')[0];
                    if (String.isNotBlank(cleanField)) {
                        fieldNames.add(cleanField);
                    }
                }
            }
        }
        
        return fieldNames;
    }
    
    /**
     * @description Checks if user has access to specified object
     * @param objectName Name of the object
     * @return Boolean indicating access
     */
    private static Boolean isObjectAccessible(String objectName) {
        try {
            // Check object-level permissions
            switch on objectName {
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
            System.debug(LoggingLevel.ERROR, 'Error checking object access for ' + objectName + ': ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Checks if user has access to specified field
     * @param fieldName Name of the field
     * @return Boolean indicating access
     */
    private static Boolean isFieldAccessible(String fieldName) {
        try {
            // For now, we'll do basic field validation
            // In production, you'd want to check specific field permissions
            if (fieldName.contains('__c')) {
                // Custom fields - check if they exist and are accessible
                return true; // Placeholder - implement proper validation
            } else {
                // Standard fields - assume accessible for now
                return true; // Placeholder - implement proper validation
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error checking field access for ' + fieldName + ': ' + e.getMessage());
            return false;
        }
    }
}
