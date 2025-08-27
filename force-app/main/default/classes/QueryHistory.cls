/**
 * @description Tracks and stores user query history for audit and analytics
 * @author Ben Siegel
 * @date 2025-08-26
 * @group AI Services
 * @version 1.0
 */
global with sharing class QueryHistory {
    
    // Constants - UPPER_SNAKE_CASE
    private static final Integer MAX_HISTORY_RECORDS = 1000;
    private static final Integer CLEANUP_BATCH_SIZE = 100;
    
    /**
     * @description Logs a new query execution
     * @param userQuery Original user query
     * @param generatedSOQL Generated SOQL query
     * @param recordCount Number of records returned
     * @param executionTime Execution time in milliseconds
     * @param success Whether query was successful
     * @param errorMessage Error message if failed
     * @return QueryHistory__c record ID
     */
    global static Id logQuery(String userQuery, String generatedSOQL, Integer recordCount, 
                             Long executionTime, Boolean success, String errorMessage) {
        String methodName = 'logQuery';
        System.debug(LoggingLevel.INFO, methodName + ' - Entry');
        
        try {
            // Create history record
            QueryHistory__c history = new QueryHistory__c(
                User_Query__c = userQuery,
                Generated_SOQL__c = generatedSOQL,
                Record_Count__c = recordCount,
                Execution_Time__c = executionTime,
                Success__c = success,
                Error_Message__c = errorMessage,
                Query_Date__c = System.now(),
                Session_ID__c = getCurrentSessionId()
            );
            
            // Try to set User__c if accessible, but don't fail if not
            try {
                history.User__c = UserInfo.getUserId();
            } catch (Exception userEx) {
                System.debug(LoggingLevel.WARN, 'Could not set User__c: ' + userEx.getMessage());
                // Continue without user reference
            }
            
            insert history;
            
            // Cleanup old records if needed
            cleanupOldRecords();
            
            System.debug(LoggingLevel.INFO, methodName + ' - Exit: History logged with ID ' + history.Id);
            return history.Id;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, methodName + ' - Error logging query: ' + e.getMessage());
            // Don't throw exception - logging failure shouldn't break main functionality
            return null;
        }
    }
    
    /**
     * @description Retrieves query history for current user
     * @param limitCount Maximum number of records to return
     * @return List of query history records
     */
    global static List<QueryHistory__c> getUserQueryHistory(Integer limitCount) {
        String methodName = 'getUserQueryHistory';
        System.debug(LoggingLevel.INFO, methodName + ' - Entry');
        
        try {
            List<QueryHistory__c> history = [
                SELECT Id, User_Query__c, Generated_SOQL__c, Record_Count__c, 
                       Execution_Time__c, Success__c, Error_Message__c, Query_Date__c
                FROM QueryHistory__c 
                WHERE User__c = :UserInfo.getUserId()
                ORDER BY Query_Date__c DESC
                LIMIT :limitCount
            ];
            
            System.debug(LoggingLevel.INFO, methodName + ' - Exit: Retrieved ' + history.size() + ' records');
            return history;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, methodName + ' - Error retrieving history: ' + e.getMessage());
            return new List<QueryHistory__c>();
        }
    }
    
    /**
     * @description Retrieves query history for all users (admin only)
     * @param limitCount Maximum number of records to return
     * @return List of query history records
     */
    global static List<QueryHistory__c> getAllQueryHistory(Integer limitCount) {
        String methodName = 'getAllQueryHistory';
        System.debug(LoggingLevel.INFO, methodName + ' - Entry');
        
        try {
            // Check if user has admin permissions
            if (!hasAdminPermissions()) {
                throw new SecurityException('Insufficient permissions to view all query history');
            }
            
            List<QueryHistory__c> history = [
                SELECT Id, User_Query__c, Generated_SOQL__c, Record_Count__c, 
                       Execution_Time__c, Success__c, Error_Message__c, Query_Date__c,
                       User__c, User__r.Name
                FROM QueryHistory__c 
                ORDER BY Query_Date__c DESC
                LIMIT :limitCount
            ];
            
            System.debug(LoggingLevel.INFO, methodName + ' - Exit: Retrieved ' + history.size() + ' records');
            return history;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, methodName + ' - Error retrieving all history: ' + e.getMessage());
            throw new QueryHistoryException('Failed to retrieve query history: ' + e.getMessage());
        }
    }
    
    /**
     * @description Retrieves query analytics and statistics
     * @return QueryAnalytics object with statistics
     */
    global static QueryAnalytics getQueryAnalytics() {
        String methodName = 'getQueryAnalytics';
        System.debug(LoggingLevel.INFO, methodName + ' - Entry');
        
        try {
            QueryAnalytics analytics = new QueryAnalytics();
            
            // Get total query count
            analytics.totalQueries = [
                SELECT COUNT() 
                FROM QueryHistory__c 
                WHERE User__c = :UserInfo.getUserId()
            ];
            
            // Get successful query count
            analytics.successfulQueries = [
                SELECT COUNT() 
                FROM QueryHistory__c 
                WHERE User__c = :UserInfo.getUserId() 
                AND Success__c = true
            ];
            
            // Get average execution time
            List<AggregateResult> avgTimeResults = [
                SELECT AVG(Execution_Time__c) avgTime
                FROM QueryHistory__c 
                WHERE User__c = :UserInfo.getUserId() 
                AND Success__c = true 
                AND Execution_Time__c > 0
            ];
            
            if (!avgTimeResults.isEmpty() && avgTimeResults[0].get('avgTime') != null) {
                analytics.averageExecutionTime = (Long) avgTimeResults[0].get('avgTime');
            }
            
            // Get most common queries
            analytics.mostCommonQueries = getMostCommonQueries();
            
            System.debug(LoggingLevel.INFO, methodName + ' - Exit: Analytics retrieved');
            return analytics;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, methodName + ' - Error retrieving analytics: ' + e.getMessage());
            return new QueryAnalytics();
        }
    }
    
    /**
     * @description Searches query history for specific terms
     * @param searchTerm Search term to look for
     * @param limitCount Maximum number of records to return
     * @return List of matching query history records
     */
    global static List<QueryHistory__c> searchQueryHistory(String searchTerm, Integer limitCount) {
        String methodName = 'searchQueryHistory';
        System.debug(LoggingLevel.INFO, methodName + ' - Entry');
        
        try {
            if (String.isBlank(searchTerm)) {
                return getUserQueryHistory(limitCount);
            }
            
            String searchPattern = '%' + searchTerm + '%';
            
            List<QueryHistory__c> results = [
                SELECT Id, User_Query__c, Generated_SOQL__c, Record_Count__c, 
                       Execution_Time__c, Success__c, Error_Message__c, Query_Date__c
                FROM QueryHistory__c 
                WHERE User__c = :UserInfo.getUserId()
                AND (User_Query__c LIKE :searchPattern 
                     OR Generated_SOQL__c LIKE :searchPattern)
                ORDER BY Query_Date__c DESC
                LIMIT :limitCount
            ];
            
            System.debug(LoggingLevel.INFO, methodName + ' - Exit: Found ' + results.size() + ' matching records');
            return results;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, methodName + ' - Error searching history: ' + e.getMessage());
            return new List<QueryHistory__c>();
        }
    }
    
    /**
     * @description Cleans up old query history records
     */
    private static void cleanupOldRecords() {
        try {
            // Count total records for current user
            Integer totalRecords = [
                SELECT COUNT() 
                FROM QueryHistory__c 
                WHERE User__c = :UserInfo.getUserId()
            ];
            
            // If over limit, delete oldest records
            if (totalRecords > MAX_HISTORY_RECORDS) {
                List<QueryHistory__c> oldRecords = [
                    SELECT Id 
                    FROM QueryHistory__c 
                    WHERE User__c = :UserInfo.getUserId()
                    ORDER BY Query_Date__c ASC
                    LIMIT :CLEANUP_BATCH_SIZE
                ];
                
                if (!oldRecords.isEmpty()) {
                    delete oldRecords;
                    System.debug(LoggingLevel.INFO, 'Cleaned up ' + oldRecords.size() + ' old query history records');
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Could not cleanup old records: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets current session ID
     * @return Session ID string
     */
    private static String getCurrentSessionId() {
        try {
            // In production, you'd get this from the actual session
            // For now, return a placeholder
            return 'session-' + System.currentTimeMillis();
        } catch (Exception e) {
            return 'unknown-session';
        }
    }
    
    /**
     * @description Checks if user has admin permissions
     * @return Boolean indicating admin access
     */
    private static Boolean hasAdminPermissions() {
        try {
            // Check if user has custom permission or is system admin
            Profile userProfile = [
                SELECT Name 
                FROM Profile 
                WHERE Id = :UserInfo.getProfileId()
            ];
            
            return userProfile.Name == 'System Administrator';
            
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Could not determine admin permissions: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Gets most common user queries
     * @return List of common query strings
     */
    private static List<String> getMostCommonQueries() {
        try {
            List<AggregateResult> commonQueries = [
                SELECT User_Query__c, COUNT(Id) queryCount
                FROM QueryHistory__c 
                WHERE User__c = :UserInfo.getUserId() 
                AND Success__c = true
                GROUP BY User_Query__c
                ORDER BY queryCount DESC
                LIMIT 5
            ];
            
            List<String> queries = new List<String>();
            for (AggregateResult result : commonQueries) {
                queries.add((String) result.get('User_Query__c'));
            }
            
            return queries;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Could not retrieve common queries: ' + e.getMessage());
            return new List<String>();
        }
    }
}

/**
 * @description Analytics data for query history
 */
global class QueryAnalytics {
    @AuraEnabled global Integer totalQueries { get; set; }
    @AuraEnabled global Integer successfulQueries { get; set; }
    @AuraEnabled global Long averageExecutionTime { get; set; }
    @AuraEnabled global List<String> mostCommonQueries { get; set; }
    
    global QueryAnalytics() {
        this.totalQueries = 0;
        this.successfulQueries = 0;
        this.averageExecutionTime = 0;
        this.mostCommonQueries = new List<String>();
    }
}

/**
 * @description Custom exception for query history errors
 */
global class QueryHistoryException extends Exception {}
