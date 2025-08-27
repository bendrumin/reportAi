/**
 * @fileoverview SOQL Builder Utility for AI Report Builder
 * @author Ben Siegel
 * @date 2025-08-26
 * @version 1.0
 * @description Converts AI responses into valid SOQL queries
 */

const salesforceMapping = require('../config/salesforceMapping');

class SOQLBuilder {
    constructor() {
        this.schema = salesforceMapping.getSchema();
    }
    
    /**
     * @description Generate SOQL query from AI response
     * @param {Object} aiResponse - AI processing response
     * @param {string} originalQuery - Original user query
     * @returns {Object} SOQL generation result
     */
    async generateSOQL(aiResponse, originalQuery) {
        try {
            if (!aiResponse.success) {
                throw new Error('AI response indicates failure');
            }
            
            const { object, fields, conditions } = aiResponse;
            
            // Validate object
            if (!this.schema.objects[object]) {
                throw new Error(`Unsupported object: ${object}`);
            }
            
            // Build SELECT clause
            const selectClause = this.buildSelectClause(fields, object);
            
            // Build FROM clause
            const fromClause = this.buildFromClause(object);
            
            // Build WHERE clause
            const whereClause = this.buildWhereClause(conditions, originalQuery, object);
            
            // Build ORDER BY clause
            const orderByClause = this.buildOrderByClause(object);
            
            // Build LIMIT clause
            const limitClause = 'LIMIT 1000';
            
            // Combine clauses
            const soql = `${selectClause} ${fromClause} ${whereClause} ${orderByClause} ${limitClause}`.trim();
            
            return {
                success: true,
                soql: soql,
                fields: fields,
                object: object,
                conditions: conditions
            };
            
        } catch (error) {
            console.error('SOQL generation error:', error);
            
            return {
                success: false,
                error: error.message,
                soql: null
            };
        }
    }
    
    /**
     * @description Build SELECT clause
     * @param {Array} fields - Fields to select
     * @param {string} object - Object name
     * @returns {string} SELECT clause
     * @private
     */
    buildSelectClause(fields, object) {
        if (!fields || fields.length === 0) {
            // Default fields based on object
            fields = this.getDefaultFields(object);
        }
        
        // Ensure Id is always included
        if (!fields.includes('Id')) {
            fields.unshift('Id');
        }
        
        // Validate fields exist in schema
        const validFields = fields.filter(field => 
            this.isFieldValid(field, object)
        );
        
        if (validFields.length === 0) {
            validFields.push('Id', 'Name');
        }
        
        return `SELECT ${validFields.join(', ')}`;
    }
    
    /**
     * @description Build FROM clause
     * @param {string} object - Object name
     * @returns {string} FROM clause
     * @private
     */
    buildFromClause(object) {
        return `FROM ${object}`;
    }
    
    /**
     * @description Build WHERE clause
     * @param {Array} conditions - AI conditions
     * @param {string} originalQuery - Original user query
     * @param {string} object - Object name
     * @returns {string} WHERE clause
     * @private
     */
    buildWhereClause(conditions, originalQuery, object) {
        const whereConditions = [];
        
        // Add AI-generated conditions
        if (conditions && conditions.length > 0) {
            whereConditions.push(...conditions);
        }
        
        // Add conditions based on original query
        const queryConditions = this.extractConditionsFromQuery(originalQuery, object);
        whereConditions.push(...queryConditions);
        
        // Add default conditions for performance
        const defaultConditions = this.getDefaultConditions(object);
        whereConditions.push(...defaultConditions);
        
        if (whereConditions.length === 0) {
            return '';
        }
        
        // Remove duplicates and empty conditions
        const uniqueConditions = [...new Set(whereConditions.filter(c => c && c.trim()))];
        
        if (uniqueConditions.length === 0) {
            return '';
        }
        
        return `WHERE ${uniqueConditions.join(' AND ')}`;
    }
    
    /**
     * @description Build ORDER BY clause
     * @param {string} object - Object name
     * @returns {string} ORDER BY clause
     * @private
     */
    buildOrderByClause(object) {
        const orderFields = this.getOrderByFields(object);
        return orderFields.length > 0 ? `ORDER BY ${orderFields.join(', ')}` : '';
    }
    
    /**
     * @description Extract conditions from natural language query
     * @param {string} query - Natural language query
     * @param {string} object - Object name
     * @returns {Array} Extracted conditions
     * @private
     */
    extractConditionsFromQuery(query, object) {
        const conditions = [];
        const lowerQuery = query.toLowerCase();
        
        // Date conditions
        if (lowerQuery.includes('this month') || lowerQuery.includes('current month')) {
            conditions.push('CreatedDate = THIS_MONTH');
        } else if (lowerQuery.includes('last month')) {
            conditions.push('CreatedDate = LAST_MONTH');
        } else if (lowerQuery.includes('this quarter')) {
            conditions.push('CreatedDate = THIS_QUARTER');
        } else if (lowerQuery.includes('last quarter')) {
            conditions.push('CreatedDate = LAST_QUARTER');
        } else if (lowerQuery.includes('this year')) {
            conditions.push('CreatedDate = THIS_YEAR');
        } else if (lowerQuery.includes('last year')) {
            conditions.push('CreatedDate = LAST_YEAR');
        }
        
        // Status conditions
        if (lowerQuery.includes('active') || lowerQuery.includes('open')) {
            if (object === 'Account') {
                conditions.push('Active__c = true');
            } else if (object === 'Opportunity') {
                conditions.push('IsClosed = false');
            } else if (object === 'Case') {
                conditions.push('Status != \'Closed\'');
            }
        }
        
        // Revenue/amount conditions
        if (lowerQuery.includes('high revenue') || lowerQuery.includes('high value')) {
            if (object === 'Opportunity') {
                conditions.push('Amount > 100000');
            } else if (object === 'Account') {
                conditions.push('AnnualRevenue > 1000000');
            }
        }
        
        // Industry conditions
        if (lowerQuery.includes('technology') || lowerQuery.includes('tech')) {
            if (object === 'Account') {
                conditions.push('Industry = \'Technology\'');
            }
        }
        
        return conditions;
    }
    
    /**
     * @description Get default fields for object
     * @param {string} object - Object name
     * @returns {Array} Default fields
     * @private
     */
    getDefaultFields(object) {
        const defaultFields = {
            'Account': ['Id', 'Name', 'Industry', 'Type', 'CreatedDate'],
            'Contact': ['Id', 'Name', 'Email', 'Phone', 'Title', 'CreatedDate'],
            'Lead': ['Id', 'Name', 'Company', 'Email', 'Status', 'CreatedDate'],
            'Opportunity': ['Id', 'Name', 'Amount', 'StageName', 'CloseDate', 'CreatedDate'],
            'Case': ['Id', 'CaseNumber', 'Subject', 'Status', 'Priority', 'CreatedDate'],
            'Task': ['Id', 'Subject', 'Status', 'Priority', 'CreatedDate'],
            'Event': ['Id', 'Subject', 'StartDateTime', 'EndDateTime', 'CreatedDate']
        };
        
        return defaultFields[object] || ['Id', 'Name', 'CreatedDate'];
    }
    
    /**
     * @description Get default conditions for object
     * @param {string} object - Object name
     * @returns {Array} Default conditions
     * @private
     */
    getDefaultConditions(object) {
        const defaultConditions = {
            'Account': ['IsDeleted = false'],
            'Contact': ['IsDeleted = false'],
            'Lead': ['IsDeleted = false'],
            'Opportunity': ['IsDeleted = false'],
            'Case': ['IsDeleted = false'],
            'Task': ['IsDeleted = false'],
            'Event': ['IsDeleted = false']
        };
        
        return defaultConditions[object] || ['IsDeleted = false'];
    }
    
    /**
     * @description Get ORDER BY fields for object
     * @param {string} object - Object name
     * @returns {Array} ORDER BY fields
     * @private
     */
    getOrderByFields(object) {
        const orderFields = {
            'Account': ['Name'],
            'Contact': ['Name'],
            'Lead': ['Name'],
            'Opportunity': ['CloseDate DESC'],
            'Case': ['CreatedDate DESC'],
            'Task': ['CreatedDate DESC'],
            'Event': ['StartDateTime']
        };
        
        return orderFields[object] || ['CreatedDate DESC'];
    }
    
    /**
     * @description Validate field exists in object
     * @param {string} field - Field name
     * @param {string} object - Object name
     * @returns {boolean} Field validity
     * @private
     */
    isFieldValid(field, object) {
        if (!this.schema.objects[object]) {
            return false;
        }
        
        return this.schema.objects[object].fields.includes(field) || 
               field.includes('__c') || // Custom fields
               ['Id', 'Name', 'CreatedDate', 'LastModifiedDate'].includes(field); // Standard fields
    }
    
    /**
     * @description Validate generated SOQL
     * @param {string} soql - SOQL query to validate
     * @returns {Object} Validation result
     */
    validateSOQL(soql) {
        try {
            if (!soql || typeof soql !== 'string') {
                return {
                    isValid: false,
                    error: 'SOQL query is required and must be a string'
                };
            }
            
            // Basic syntax validation
            const upperSoql = soql.toUpperCase();
            
            // Check required clauses
            if (!upperSoql.includes('SELECT ')) {
                return {
                    isValid: false,
                    error: 'Missing SELECT clause'
                };
            }
            
            if (!upperSoql.includes(' FROM ')) {
                return {
                    isValid: false,
                    error: 'Missing FROM clause'
                };
            }
            
            // Check for forbidden keywords
            const forbiddenKeywords = ['INSERT', 'UPDATE', 'DELETE', 'DROP', 'CREATE', 'ALTER'];
            for (const keyword of forbiddenKeywords) {
                if (upperSoql.includes(keyword)) {
                    return {
                        isValid: false,
                        error: `Forbidden keyword detected: ${keyword}`
                    };
                }
            }
            
            // Check LIMIT clause
            if (!upperSoql.includes(' LIMIT ')) {
                return {
                    isValid: false,
                    error: 'Missing LIMIT clause for performance'
                };
            }
            
            // Check LIMIT value
            const limitMatch = soql.match(/LIMIT\s+(\d+)/i);
            if (limitMatch) {
                const limitValue = parseInt(limitMatch[1]);
                if (limitValue > 2000) {
                    return {
                        isValid: false,
                        error: 'LIMIT value cannot exceed 2000'
                    };
                }
            }
            
            return {
                isValid: true,
                error: null
            };
            
        } catch (error) {
            return {
                isValid: false,
                error: 'SOQL validation failed: ' + error.message
            };
        }
    }
}

module.exports = new SOQLBuilder();
