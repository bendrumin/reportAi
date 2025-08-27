/**
 * @fileoverview Salesforce Mapping Configuration for AI Report Builder
 * @author Ben Siegel
 * @date 2025-08-26
 * @version 1.0
 * @description Defines Salesforce object and field mappings for AI processing
 */

class SalesforceMapping {
    constructor() {
        this.schema = this.buildSchema();
        this.businessTerms = this.buildBusinessTerms();
    }
    
    /**
     * @description Build Salesforce schema configuration
     * @returns {Object} Schema configuration
     * @private
     */
    buildSchema() {
        return {
            objects: {
                'Account': {
                    label: 'Account',
                    fields: [
                        'Id', 'Name', 'AccountNumber', 'Type', 'Industry', 'Rating', 'Phone', 'Fax',
                        'Website', 'PhotoUrl', 'BillingStreet', 'BillingCity', 'BillingState',
                        'BillingPostalCode', 'BillingCountry', 'ShippingStreet', 'ShippingCity',
                        'ShippingState', 'ShippingPostalCode', 'ShippingCountry', 'Description',
                        'NumberOfEmployees', 'AnnualRevenue', 'OwnerId', 'CreatedDate', 'CreatedById',
                        'LastModifiedDate', 'LastModifiedById', 'SystemModstamp', 'LastActivityDate',
                        'LastViewedDate', 'LastReferencedDate', 'IsDeleted', 'MasterRecordId',
                        'ParentId', 'Active__c', 'AUM__c', 'Client_Since__c', 'Priority__c'
                    ],
                    relationships: ['Parent', 'Contacts', 'Opportunities', 'Cases', 'Tasks', 'Events']
                },
                'Contact': {
                    label: 'Contact',
                    fields: [
                        'Id', 'IsDeleted', 'MasterRecordId', 'AccountId', 'LastName', 'FirstName',
                        'Salutation', 'Name', 'OtherStreet', 'OtherCity', 'OtherState', 'OtherPostalCode',
                        'OtherCountry', 'MailingStreet', 'MailingCity', 'MailingState', 'MailingPostalCode',
                        'MailingCountry', 'Phone', 'Fax', 'MobilePhone', 'HomePhone', 'OtherPhone',
                        'AssistantPhone', 'ReportsToId', 'Email', 'Title', 'Department', 'AssistantName',
                        'LeadSource', 'Birthdate', 'Description', 'CreatedDate', 'CreatedById',
                        'LastModifiedDate', 'LastModifiedById', 'SystemModstamp', 'LastActivityDate',
                        'LastCURequestDate', 'LastCUUpdateDate', 'LastViewedDate', 'LastReferencedDate',
                        'EmailBouncedReason', 'EmailBouncedDate', 'IsEmailBounced', 'PhotoUrl',
                        'Jigsaw', 'JigsawContactId', 'CleanStatus', 'IndividualId', 'Level__c',
                        'Languages__c', 'Birthday_Month__c', 'VIP_Status__c'
                    ],
                    relationships: ['Account', 'ReportsTo', 'Opportunities', 'Cases', 'Tasks', 'Events']
                },
                'Lead': {
                    label: 'Lead',
                    fields: [
                        'Id', 'IsDeleted', 'MasterRecordId', 'LastName', 'FirstName', 'Salutation',
                        'Name', 'Title', 'Company', 'Street', 'City', 'State', 'PostalCode', 'Country',
                        'Phone', 'MobilePhone', 'Fax', 'Email', 'Website', 'PhotoUrl', 'Description',
                        'LeadSource', 'Status', 'Industry', 'Rating', 'AnnualRevenue', 'NumberOfEmployees',
                        'OwnerId', 'IsConverted', 'ConvertedDate', 'ConvertedAccountId', 'ConvertedContactId',
                        'ConvertedOpportunityId', 'IsUnreadByOwner', 'CreatedDate', 'CreatedById',
                        'LastModifiedDate', 'LastModifiedById', 'SystemModstamp', 'LastActivityDate',
                        'LastViewedDate', 'LastReferencedDate', 'Jigsaw', 'JigsawContactId', 'CleanStatus',
                        'IndividualId', 'CompanyDunsNumber', 'DandbCompanyId', 'EmailBouncedReason',
                        'EmailBouncedDate', 'IsEmailBounced', 'SICCode__c', 'ProductInterest__c',
                        'Primary__c', 'CurrentGenerators__c', 'NumberofLocations__c'
                    ],
                    relationships: ['Owner', 'ConvertedAccount', 'ConvertedContact', 'ConvertedOpportunity']
                },
                'Opportunity': {
                    label: 'Opportunity',
                    fields: [
                        'Id', 'IsDeleted', 'AccountId', 'RecordTypeId', 'Name', 'Amount', 'CloseDate',
                        'StageName', 'Type', 'Probability', 'ExpectedRevenue', 'TotalOpportunityQuantity',
                        'CloseDate', 'Type', 'NextStep', 'LeadSource', 'IsClosed', 'IsWon', 'ForecastCategory',
                        'ForecastCategoryName', 'CampaignId', 'HasOpportunityLineItem', 'Pricebook2Id',
                        'OwnerId', 'CreatedDate', 'CreatedById', 'LastModifiedDate', 'LastModifiedById',
                        'SystemModstamp', 'LastActivityDate', 'LastStageChangeDate', 'FiscalYear',
                        'FiscalQuarter', 'Fiscal', 'ContactId', 'LastViewedDate', 'LastReferencedDate',
                        'Description', 'Type', 'LeadSource', 'HasOpenActivity', 'HasOverdueTask',
                        'DeliveryInstallationStatus__c', 'TrackingNumber__c', 'OrderNumber__c',
                        'CurrentGenerators__c', 'MainCompetitors__c', 'DeliveryInstallationStatus__c'
                    ],
                    relationships: ['Account', 'Contact', 'Owner', 'Campaign', 'Pricebook2', 'OpportunityLineItems']
                },
                'Case': {
                    label: 'Case',
                    fields: [
                        'Id', 'IsDeleted', 'CaseNumber', 'ContactId', 'AccountId', 'AssetId', 'ParentId',
                        'SuppliedName', 'SuppliedEmail', 'SuppliedPhone', 'SuppliedCompany', 'Type',
                        'Status', 'Reason', 'Origin', 'Subject', 'Priority', 'Description', 'IsClosed',
                        'IsEscalated', 'OwnerId', 'CreatedDate', 'CreatedById', 'LastModifiedDate',
                        'LastModifiedById', 'SystemModstamp', 'LastViewedDate', 'LastReferencedDate',
                        'ClosedDate', 'IsClosedOnCreate', 'EscalationStartTime', 'BusinessHoursId',
                        'IsStopped', 'StopStartDate', 'ContactEmail', 'ContactPhone', 'ContactMobile',
                        'ContactFax', 'Comments', 'LastCaseUpdate', 'CreatedByRole', 'LastModifiedByRole',
                        'IsVisibleInSelfService', 'Days_Since_Last_Update__c', 'Escalation_Level__c',
                        'SLA_Breach__c', 'Customer_Satisfaction__c'
                    ],
                    relationships: ['Account', 'Contact', 'Asset', 'Parent', 'Owner', 'BusinessHours']
                },
                'Task': {
                    label: 'Task',
                    fields: [
                        'Id', 'WhoId', 'WhatId', 'WhoCount', 'WhatCount', 'Subject', 'ActivityDate',
                        'Status', 'Priority', 'Description', 'Type', 'IsDeleted', 'AccountId', 'IsArchived',
                        'CallDurationInSeconds', 'CallType', 'CallDisposition', 'CallObject', 'ReminderDateTime',
                        'IsReminderSet', 'RecurrenceActivityId', 'IsRecurrence', 'RecurrenceStartDateOnly',
                        'RecurrenceEndDateOnly', 'RecurrenceTimeZoneSidKey', 'RecurrenceType', 'RecurrenceInterval',
                        'RecurrenceDayOfWeekMask', 'RecurrenceDayOfMonth', 'RecurrenceInstance',
                        'RecurrenceMonthOfYear', 'RecurrenceRegeneratedType', 'TaskSubtype', 'CompletedDateTime',
                        'CreatedDate', 'CreatedById', 'LastModifiedDate', 'LastModifiedById', 'SystemModstamp',
                        'IsArchived', 'CallDurationInSeconds', 'CallType', 'CallDisposition', 'CallObject',
                        'ReminderDateTime', 'IsReminderSet', 'RecurrenceActivityId', 'IsRecurrence',
                        'RecurrenceStartDateOnly', 'RecurrenceEndDateOnly', 'RecurrenceTimeZoneSidKey',
                        'RecurrenceType', 'RecurrenceInterval', 'RecurrenceDayOfWeekMask', 'RecurrenceDayOfMonth',
                        'RecurrenceInstance', 'RecurrenceMonthOfYear', 'RecurrenceRegeneratedType',
                        'TaskSubtype', 'CompletedDateTime', 'CreatedDate', 'CreatedById', 'LastModifiedDate',
                        'LastModifiedById', 'SystemModstamp', 'IsArchived', 'CallDurationInSeconds',
                        'CallType', 'CallDisposition', 'CallObject', 'ReminderDateTime', 'IsReminderSet',
                        'RecurrenceActivityId', 'IsRecurrence', 'RecurrenceStartDateOnly', 'RecurrenceEndDateOnly',
                        'RecurrenceTimeZoneSidKey', 'RecurrenceType', 'RecurrenceInterval', 'RecurrenceDayOfWeekMask',
                        'RecurrenceDayOfMonth', 'RecurrenceInstance', 'RecurrenceMonthOfYear',
                        'RecurrenceRegeneratedType', 'TaskSubtype', 'CompletedDateTime', 'CreatedDate',
                        'CreatedById', 'LastModifiedDate', 'LastModifiedById', 'SystemModstamp'
                    ],
                    relationships: ['Who', 'What', 'Account', 'Owner']
                },
                'Event': {
                    label: 'Event',
                    fields: [
                        'Id', 'WhoId', 'WhatId', 'WhoCount', 'WhatCount', 'Subject', 'Location',
                        'IsAllDayEvent', 'ActivityDateTime', 'ActivityDate', 'DurationInMinutes',
                        'StartDateTime', 'EndDateTime', 'Description', 'Type', 'IsPrivate', 'ShowAs',
                        'IsDeleted', 'IsArchived', 'IsGroupEvent', 'GroupEventType', 'CreatedDate',
                        'CreatedById', 'LastModifiedDate', 'LastModifiedById', 'SystemModstamp',
                        'IsArchived', 'RecurrenceActivityId', 'IsRecurrence', 'RecurrenceStartDateOnly',
                        'RecurrenceEndDateOnly', 'RecurrenceTimeZoneSidKey', 'RecurrenceType',
                        'RecurrenceInterval', 'RecurrenceDayOfWeekMask', 'RecurrenceDayOfMonth',
                        'RecurrenceInstance', 'RecurrenceMonthOfYear', 'RecurrenceRegeneratedType',
                        'Subject', 'Location', 'IsAllDayEvent', 'ActivityDateTime', 'ActivityDate',
                        'DurationInMinutes', 'StartDateTime', 'EndDateTime', 'Description', 'Type',
                        'IsPrivate', 'ShowAs', 'IsDeleted', 'IsArchived', 'IsGroupEvent', 'GroupEventType'
                    ],
                    relationships: ['Who', 'What', 'Owner']
                }
            }
        };
    }
    
    /**
     * @description Build business term mappings
     * @returns {Object} Business term mappings
     * @private
     */
    buildBusinessTerms() {
        return {
            // Object mappings
            'customers': 'Account',
            'accounts': 'Account',
            'companies': 'Account',
            'organizations': 'Account',
            'contacts': 'Contact',
            'people': 'Contact',
            'individuals': 'Contact',
            'leads': 'Lead',
            'prospects': 'Lead',
            'opportunities': 'Opportunity',
            'deals': 'Opportunity',
            'sales': 'Opportunity',
            'cases': 'Case',
            'support': 'Case',
            'tickets': 'Case',
            'tasks': 'Task',
            'activities': 'Task',
            'events': 'Event',
            'meetings': 'Event',
            'appointments': 'Event',
            
            // Status mappings
            'active': 'Active',
            'inactive': 'Inactive',
            'open': 'Open',
            'closed': 'Closed',
            'won': 'Won',
            'lost': 'Lost',
            'pending': 'Pending',
            'draft': 'Draft',
            'submitted': 'Submitted',
            'approved': 'Approved',
            'rejected': 'Rejected',
            
            // Industry mappings
            'technology': 'Technology',
            'tech': 'Technology',
            'software': 'Technology',
            'healthcare': 'Healthcare',
            'medical': 'Healthcare',
            'finance': 'Financial Services',
            'banking': 'Financial Services',
            'insurance': 'Financial Services',
            'manufacturing': 'Manufacturing',
            'retail': 'Retail',
            'education': 'Education',
            'government': 'Government',
            'nonprofit': 'Non-Profit',
            
            // Priority mappings
            'high': 'High',
            'medium': 'Medium',
            'low': 'Low',
            'urgent': 'High',
            'critical': 'High',
            'normal': 'Medium',
            'minor': 'Low'
        };
    }
    
    /**
     * @description Get schema configuration
     * @returns {Object} Schema configuration
     */
    getSchema() {
        return this.schema;
    }
    
    /**
     * @description Get business term mappings
     * @returns {Object} Business term mappings
     */
    getBusinessTerms() {
        return this.businessTerms;
    }
    
    /**
     * @description Map business term to Salesforce object
     * @param {string} term - Business term
     * @returns {string} Salesforce object name
     */
    mapBusinessTerm(term) {
        const lowerTerm = term.toLowerCase();
        return this.businessTerms[lowerTerm] || term;
    }
    
    /**
     * @description Get available objects
     * @returns {Array} List of available objects
     */
    getAvailableObjects() {
        return Object.keys(this.schema.objects);
    }
    
    /**
     * @description Get fields for specific object
     * @param {string} objectName - Object name
     * @returns {Array} List of fields
     */
    getObjectFields(objectName) {
        if (this.schema.objects[objectName]) {
            return this.schema.objects[objectName].fields;
        }
        return [];
    }
    
    /**
     * @description Get relationships for specific object
     * @param {string} objectName - Object name
     * @returns {Array} List of relationships
     */
    getObjectRelationships(objectName) {
        if (this.schema.objects[objectName]) {
            return this.schema.objects[objectName].relationships;
        }
        return [];
    }
    
    /**
     * @description Validate object exists
     * @param {string} objectName - Object name
     * @returns {boolean} Object validity
     */
    isValidObject(objectName) {
        return this.schema.objects.hasOwnProperty(objectName);
    }
    
    /**
     * @description Validate field exists in object
     * @param {string} fieldName - Field name
     * @param {string} objectName - Object name
     * @returns {boolean} Field validity
     */
    isValidField(fieldName, objectName) {
        if (!this.isValidObject(objectName)) {
            return false;
        }
        
        const fields = this.getObjectFields(objectName);
        return fields.includes(fieldName);
    }
}

module.exports = new SalesforceMapping();
