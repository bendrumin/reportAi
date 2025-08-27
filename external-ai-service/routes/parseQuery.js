/**
 * @fileoverview Parse Query Route for AI Report Builder
 * @author Ben Siegel
 * @date 2025-08-26
 * @version 1.0
 * @description Handles natural language query processing and SOQL generation
 */

const express = require('express');
const router = express.Router();
const openaiService = require('../services/openaiService');
const soqlBuilder = require('../utils/soqlBuilder');
const salesforceMapping = require('../config/salesforceMapping');

/**
 * @description Parse natural language query and generate SOQL
 * @route POST /api/parse-query
 * @access Public
 */
router.post('/parse-query', async (req, res) => {
    try {
        const { query, userId, orgId } = req.body;
        
        // Validate input
        if (!query || typeof query !== 'string') {
            return res.status(400).json({
                success: false,
                error: 'Invalid input',
                message: 'Query parameter is required and must be a string'
            });
        }
        
        if (query.length > 1000) {
            return res.status(400).json({
                success: false,
                error: 'Input too long',
                message: 'Query exceeds maximum length of 1000 characters'
            });
        }
        
        console.log(`Processing query: "${query}" from user ${userId} in org ${orgId}`);
        
        // Process query with OpenAI
        const aiResponse = await openaiService.processQuery(query);
        
        if (!aiResponse.success) {
            return res.status(500).json({
                success: false,
                error: 'AI processing failed',
                message: aiResponse.error || 'Failed to process query with AI service'
            });
        }
        
        // Generate SOQL from AI response
        const soqlResult = await soqlBuilder.generateSOQL(aiResponse, query);
        
        if (!soqlResult.success) {
            return res.status(500).json({
                success: false,
                error: 'SOQL generation failed',
                message: soqlResult.error || 'Failed to generate SOQL query'
            });
        }
        
        // Validate generated SOQL
        const validationResult = soqlBuilder.validateSOQL(soqlResult.soql);
        
        if (!validationResult.isValid) {
            return res.status(400).json({
                success: false,
                error: 'Invalid SOQL generated',
                message: validationResult.error || 'Generated SOQL is invalid',
                details: validationResult.details
            });
        }
        
        // Build response
        const response = {
            success: true,
            soqlQuery: soqlResult.soql,
            explanation: aiResponse.explanation || `Generated SOQL query for: "${query}"`,
            fields: soqlResult.fields || [],
            metadata: {
                originalQuery: query,
                userId: userId,
                orgId: orgId,
                timestamp: new Date().toISOString(),
                processingTime: Date.now() - req.startTime
            }
        };
        
        console.log(`Successfully processed query. Generated SOQL: ${soqlResult.soql}`);
        
        res.status(200).json(response);
        
    } catch (error) {
        console.error('Error processing query:', error);
        
        res.status(500).json({
            success: false,
            error: 'Internal server error',
            message: 'Failed to process query',
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

/**
 * @description Get available Salesforce objects and fields
 * @route GET /api/salesforce-schema
 * @access Public
 */
router.get('/salesforce-schema', (req, res) => {
    try {
        const schema = salesforceMapping.getSchema();
        
        res.status(200).json({
            success: true,
            schema: schema
        });
        
    } catch (error) {
        console.error('Error retrieving schema:', error);
        
        res.status(500).json({
            success: false,
            error: 'Internal server error',
            message: 'Failed to retrieve Salesforce schema'
        });
    }
});

/**
 * @description Health check for parse query service
 * @route GET /api/parse-query/health
 * @access Public
 */
router.get('/parse-query/health', (req, res) => {
    res.status(200).json({
        success: true,
        service: 'Parse Query Service',
        status: 'healthy',
        timestamp: new Date().toISOString(),
        openai: openaiService.isConfigured() ? 'configured' : 'not configured'
    });
});

module.exports = router;
