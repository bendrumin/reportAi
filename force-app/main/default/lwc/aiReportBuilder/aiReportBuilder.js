/**
 * @fileoverview AI Report Builder Lightning Web Component
 * @author Ben Siegel
 * @date 2025-08-26
 * @version 1.0
 * @description Provides conversational interface for Salesforce report generation
 */

import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import processQuery from '@salesforce/apex/AIReportService.processQuery';
import createReportFromResults from '@salesforce/apex/ReportGenerator.createReportFromResults';
import getUserQueryHistory from '@salesforce/apex/QueryHistory.getUserQueryHistory';

/**
 * AI Report Builder Component
 * @extends LightningElement
 */
export default class AiReportBuilder extends LightningElement {
    
    // Constants
    static QUERY_MIN_LENGTH = 5;
    static MAX_RESULTS_DISPLAY = 100;
    static MAX_HISTORY_RECORDS = 50;
    
    // Private properties (underscore prefix)
    _isProcessing = false;
    _queryHistory = [];
    _currentQuery = '';
    _startTime = 0;
    
    // Public API properties
    @api recordId;
    @api objectApiName;
    @api title = 'AI Report Builder';
    
    // Tracked properties for reactivity
    @track messages = [];
    @track queryResults = {};
    @track errorState = null;
    @track currentQuery = '';
    
    // Computed properties
    get isQueryDisabled() {
        return this._isProcessing || 
               !this._currentQuery || 
               this._currentQuery.length < AiReportBuilder.QUERY_MIN_LENGTH;
    }
    
    get hasResults() {
        return this.queryResults && 
               this.queryResults.results && 
               this.queryResults.results.length > 0;
    }
    
    get isClearDisabled() {
        return !this.hasResults;
    }
    
    get isSaveDisabled() {
        return !this.hasResults;
    }
    
    get hasMessages() {
        return this.messages && this.messages.length > 0;
    }
    
    get displayedResults() {
        return this.hasResults ? 
               this.queryResults.results.slice(0, AiReportBuilder.MAX_RESULTS_DISPLAY) : 
               [];
    }
    
    get hasMoreResults() {
        return this.hasResults && 
               this.queryResults.results.length > AiReportBuilder.MAX_RESULTS_DISPLAY;
    }
    
    get maxDisplayResults() {
        return AiReportBuilder.MAX_RESULTS_DISPLAY;
    }
    
    get recordCount() {
        return this.hasResults ? this.queryResults.results.length : 0;
    }
    
    get generatedSOQL() {
        return this.hasResults ? this.queryResults.soqlQuery : '';
    }
    
    get tableHeaders() {
        if (!this.hasResults || this.queryResults.results.length === 0) {
            return [];
        }
        
        // Get field names from first record
        const firstRecord = this.queryResults.results[0];
        return Object.keys(firstRecord).filter(key => 
            key !== 'Id' && 
            key !== 'attributes' && 
            typeof firstRecord[key] !== 'object'
        );
    }
    
    get messageClass() {
        return 'slds-chat-message__text slds-var-p-around_small';
    }
    
    get currentTimestamp() {
        return new Date().toLocaleString();
    }
    
    /**
     * Component lifecycle - connected callback
     */
    connectedCallback() {
        this._initializeComponent();
    }
    
    /**
     * Component lifecycle - disconnected callback  
     */
    disconnectedCallback() {
        this._cleanup();
    }
    
    // Event handlers (handle prefix)
    
    /**
     * @description Handles query input changes
     * @param {Event} event - Input change event
     */
    handleQueryInput(event) {
        this._currentQuery = event.target.value;
        this.currentQuery = this._currentQuery;
        this._validateQueryInput();
    }
    
    /**
     * @description Handles query submission
     * @param {Event} event - Submit event
     */
    handleQuerySubmit(event) {
        event.preventDefault();
        if (!this.isQueryDisabled) {
            this._processUserQuery();
        }
    }
    
    /**
     * @description Handles clearing results
     */
    handleClearResults() {
        this._resetQueryState();
    }
    
    /**
     * @description Handles saving report
     */
    handleSaveReport() {
        this._saveReport();
    }
    
    // Private methods (underscore prefix)
    
    /**
     * @description Initialize component state and setup
     * @private
     */
    _initializeComponent() {
        this.messages = [];
        this._queryHistory = [];
        this._loadQueryHistory();
        this._addWelcomeMessage();
    }
    
    /**
     * @description Add welcome message to chat
     * @private
     */
    _addWelcomeMessage() {
        this._addMessage('assistant', 
            'Hello! I\'m your AI Report Builder. I can help you create Salesforce reports using natural language. ' +
            'Try asking me something like "Show me accounts with high revenue" or "Find contacts created this month."');
    }
    
    /**
     * @description Process user query through AI service
     * @private
     */
    async _processUserQuery() {
        this._startTime = Date.now();
        this._isProcessing = true;
        this.errorState = null;
        
        try {
            this._addMessage('user', this._currentQuery);
            
            const result = await processQuery({ 
                query: this._currentQuery 
            });
            
            if (result.success) {
                this.queryResults = result;
                this._addMessage('assistant', result.explanation || 'Query executed successfully!');
                this._saveToHistory(this._currentQuery, result);
                this._showSuccessToast('Report generated successfully', 
                    `${result.recordCount} records found`);
            } else {
                throw new Error(result.errorMessage || 'Query processing failed');
            }
            
        } catch (error) {
            this._handleQueryError(error);
        } finally {
            this._isProcessing = false;
        }
    }
    
    /**
     * @description Add message to chat interface
     * @param {string} type - Message type ('user' or 'assistant')
     * @param {string} content - Message content
     * @private
     */
    _addMessage(type, content) {
        this.messages = [
            ...this.messages,
            {
                id: this._generateMessageId(),
                type: type,
                content: content,
                timestamp: new Date().toLocaleTimeString()
            }
        ];
    }
    
    /**
     * @description Handle query processing errors
     * @param {Error} error - Error object
     * @private
     */
    _handleQueryError(error) {
        console.error('Query processing error:', error);
        this.errorState = error.message;
        
        this._showErrorToast('Query Error', error.message);
        this._addMessage('assistant', 
            'Sorry, I encountered an error processing your request. Please try again or rephrase your query.');
    }
    
    /**
     * @description Validate query input and update UI state
     * @private
     */
    _validateQueryInput() {
        const isValid = this._currentQuery && 
                       this._currentQuery.length >= AiReportBuilder.QUERY_MIN_LENGTH;
        
        // Update UI state based on validation
        this._updateValidationState(isValid);
    }
    
    /**
     * @description Update validation state in UI
     * @param {boolean} isValid - Whether input is valid
     * @private
     */
    _updateValidationState(isValid) {
        const inputElement = this.template.querySelector('#query-input');
        if (inputElement) {
            if (isValid) {
                inputElement.classList.remove('slds-has-error');
            } else {
                inputElement.classList.add('slds-has-error');
            }
        }
    }
    
    /**
     * @description Reset query state and clear results
     * @private
     */
    _resetQueryState() {
        this.queryResults = {};
        this.errorState = null;
        this._addMessage('assistant', 'Results cleared. Ready for your next query!');
    }
    
    /**
     * @description Save query to history
     * @param {string} query - User query
     * @param {Object} result - Query result
     * @private
     */
    _saveToHistory(query, result) {
        try {
            const historyEntry = {
                query: query,
                result: result,
                timestamp: new Date()
            };
            
            this._queryHistory.unshift(historyEntry);
            
            // Keep only recent history
            if (this._queryHistory.length > AiReportBuilder.MAX_HISTORY_RECORDS) {
                this._queryHistory = this._queryHistory.slice(0, AiReportBuilder.MAX_HISTORY_RECORDS);
            }
            
        } catch (error) {
            console.warn('Failed to save to history:', error);
        }
    }
    
    /**
     * @description Save report to Salesforce
     * @private
     */
    async _saveReport() {
        try {
            if (!this.hasResults) {
                throw new Error('No results to save');
            }
            
            const reportName = `AI Report - ${this._currentQuery.substring(0, 50)}`;
            
            const reportId = await createReportFromResults({
                reportName: reportName,
                queryResults: this.queryResults.results,
                soqlQuery: this.queryResults.soqlQuery
            });
            
            this._showSuccessToast('Report Saved', 
                `Report "${reportName}" has been created successfully.`);
            
            this._addMessage('assistant', 
                `Report saved successfully! You can find it in your Reports tab.`);
            
        } catch (error) {
            console.error('Failed to save report:', error);
            this._showErrorToast('Save Error', 
                'Failed to save report: ' + error.message);
        }
    }
    
    /**
     * @description Load query history from Salesforce
     * @private
     */
    async _loadQueryHistory() {
        try {
            const history = await getUserQueryHistory({
                limitCount: AiReportBuilder.MAX_HISTORY_RECORDS
            });
            
            if (history && history.length > 0) {
                this._queryHistory = history.map(record => ({
                    query: record.User_Query__c,
                    result: {
                        soqlQuery: record.Generated_SOQL__c,
                        recordCount: record.Record_Count__c,
                        success: record.Success__c
                    },
                    timestamp: new Date(record.Query_Date__c)
                }));
            }
            
        } catch (error) {
            console.warn('Failed to load query history:', error);
        }
    }
    
    /**
     * @description Generate unique message ID
     * @returns {string} Unique identifier
     * @private
     */
    _generateMessageId() {
        return `msg-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    }
    
    /**
     * @description Show success toast notification
     * @param {string} title - Toast title
     * @param {string} message - Toast message
     * @private
     */
    _showSuccessToast(title, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: 'success'
            })
        );
    }
    
    /**
     * @description Show error toast notification
     * @param {string} title - Toast title
     * @param {string} message - Toast message
     * @private
     */
    _showErrorToast(title, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: 'error',
                mode: 'sticky'
            })
        );
    }
    
    /**
     * @description Cleanup component resources
     * @private
     */
    _cleanup() {
        this._queryHistory = [];
        this.messages = [];
        this.queryResults = {};
    }
}
