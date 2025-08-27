/**
 * @fileoverview OpenAI Service for AI Report Builder
 * @author Ben Siegel
 * @date 2025-08-26
 * @version 1.0
 * @description Handles OpenAI API integration for natural language processing
 */

const OpenAI = require('openai');

class OpenAIService {
    constructor() {
        this.openai = null;
        this.isConfigured = false;
        this.initialize();
    }
    
    /**
     * @description Initialize OpenAI client
     * @private
     */
    initialize() {
        const apiKey = process.env.OPENAI_API_KEY;
        
        if (!apiKey) {
            console.warn('OpenAI API key not configured. AI features will be limited.');
            return;
        }
        
        try {
            this.openai = new OpenAI({
                apiKey: apiKey,
                maxRetries: 3,
                timeout: 30000
            });
            this.isConfigured = true;
            console.log('OpenAI service initialized successfully');
        } catch (error) {
            console.error('Failed to initialize OpenAI service:', error);
        }
    }
    
    /**
     * @description Process natural language query with OpenAI
     * @param {string} query - User's natural language query
     * @returns {Object} Processed query response
     */
    async processQuery(query) {
        if (!this.isConfigured) {
            return this.fallbackProcessing(query);
        }
        
        try {
            const systemPrompt = this.buildSystemPrompt();
            const userPrompt = this.buildUserPrompt(query);
            
            const completion = await this.openai.chat.completions.create({
                model: 'gpt-4',
                messages: [
                    { role: 'system', content: systemPrompt },
                    { role: 'user', content: userPrompt }
                ],
                temperature: 0.1,
                max_tokens: 1000,
                timeout: 25000
            });
            
            const response = completion.choices[0].message.content;
            return this.parseAIResponse(response, query);
            
        } catch (error) {
            console.error('OpenAI API error:', error);
            return this.fallbackProcessing(query);
        }
    }
    
    /**
     * @description Build system prompt for OpenAI
     * @returns {string} System prompt
     * @private
     */
    buildSystemPrompt() {
        return `You are a Salesforce SOQL expert. Convert natural language to valid SOQL queries.

Available Standard Objects: Account, Contact, Lead, Opportunity, Case, Task, Event
Common Custom Fields: AUM__c (Account), Birthday_Month__c (Contact), Revenue__c (Opportunity)

Rules:
1. Use proper API field names (e.g., Name, Industry, Amount, StageName)
2. Handle date functions (CALENDAR_MONTH, LAST_N_DAYS, THIS_MONTH, etc.)
3. Include relevant fields for reporting (Id, Name, CreatedDate, etc.)
4. Add LIMIT 1000 for performance
5. Validate relationships exist (Account.Industry, Contact.Account.Name)
6. Use proper SOQL syntax and operators
7. Handle common business terms:
   - "customers" → Account
   - "deals" → Opportunity
   - "leads" → Lead
   - "cases" → Case
   - "high revenue" → Amount > 100000
   - "this month" → CreatedDate = THIS_MONTH
   - "last quarter" → CreatedDate = LAST_QUARTER

Return JSON format:
{
  "intent": "query description",
  "object": "main object name",
  "fields": ["field1", "field2"],
  "conditions": ["condition1", "condition2"],
  "explanation": "human readable explanation"
}`;
    }
    
    /**
     * @description Build user prompt for specific query
     * @param {string} query - User query
     * @returns {string} User prompt
     * @private
     */
    buildUserPrompt(query) {
        return `Convert this natural language query to SOQL: "${query}"

Please analyze the intent and return a structured response that can be converted to valid SOQL.`;
    }
    
    /**
     * @description Parse AI response and extract structured data
     * @param {string} response - AI response text
     * @param {string} originalQuery - Original user query
     * @returns {Object} Parsed response
     * @private
     */
    parseAIResponse(response, originalQuery) {
        try {
            // Try to extract JSON from response
            const jsonMatch = response.match(/\{[\s\S]*\}/);
            
            if (jsonMatch) {
                const parsed = JSON.parse(jsonMatch[0]);
                
                return {
                    success: true,
                    intent: parsed.intent || originalQuery,
                    object: parsed.object || 'Account',
                    fields: parsed.fields || ['Id', 'Name'],
                    conditions: parsed.conditions || [],
                    explanation: parsed.explanation || `Generated query for: ${originalQuery}`
                };
            }
            
            // Fallback parsing if JSON extraction fails
            return this.parseTextResponse(response, originalQuery);
            
        } catch (error) {
            console.warn('Failed to parse AI response as JSON:', error);
            return this.parseTextResponse(response, originalQuery);
        }
    }
    
    /**
     * @description Parse text response when JSON parsing fails
     * @param {string} response - AI response text
     * @param {string} originalQuery - Original user query
     * @returns {Object} Parsed response
     * @private
     */
    parseTextResponse(response, originalQuery) {
        // Extract object name from response
        const objectMatch = response.match(/(Account|Contact|Lead|Opportunity|Case|Task|Event)/i);
        const object = objectMatch ? objectMatch[1] : 'Account';
        
        // Extract fields mentioned
        const fieldMatches = response.match(/\b(Name|Id|CreatedDate|Industry|Amount|StageName|Status|Email|Phone)\b/gi);
        const fields = fieldMatches ? [...new Set(fieldMatches.map(f => f))] : ['Id', 'Name'];
        
        return {
            success: true,
            intent: originalQuery,
            object: object,
            fields: fields,
            conditions: [],
            explanation: `AI processed: ${originalQuery}`
        };
    }
    
    /**
     * @description Fallback processing when OpenAI is not available
     * @param {string} query - User query
     * @returns {Object} Basic processed response
     * @private
     */
    fallbackProcessing(query) {
        console.log('Using fallback processing for query:', query);
        
        // Simple keyword-based processing
        const lowerQuery = query.toLowerCase();
        
        let object = 'Account';
        if (lowerQuery.includes('contact') || lowerQuery.includes('person')) {
            object = 'Contact';
        } else if (lowerQuery.includes('lead')) {
            object = 'Lead';
        } else if (lowerQuery.includes('opportunity') || lowerQuery.includes('deal')) {
            object = 'Opportunity';
        } else if (lowerQuery.includes('case') || lowerQuery.includes('support')) {
            object = 'Case';
        }
        
        const fields = ['Id', 'Name', 'CreatedDate'];
        
        return {
            success: true,
            intent: query,
            object: object,
            fields: fields,
            conditions: [],
            explanation: `Basic processing: ${query} (OpenAI not available)`
        };
    }
    
    /**
     * @description Check if OpenAI service is configured
     * @returns {boolean} Configuration status
     */
    isConfigured() {
        return this.isConfigured;
    }
    
    /**
     * @description Get service status
     * @returns {Object} Service status information
     */
    getStatus() {
        return {
            configured: this.isConfigured,
            apiKey: this.isConfigured ? 'configured' : 'not configured',
            model: 'gpt-4',
            timeout: 25000
        };
    }
}

module.exports = new OpenAIService();
