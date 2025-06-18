/**
 * Claude Code Windows Installer - Progress Tracking System
 * 
 * Centralized progress tracking for installation steps with UI integration capabilities.
 * Designed to work with PowerShell automation and NSIS installer UI.
 */

const fs = require('fs');
const path = require('path');

class ProgressTracker {
    constructor(totalSteps, logPath = null) {
        this.totalSteps = totalSteps;
        this.currentStep = 0;
        this.stepDetails = [];
        this.startTime = new Date();
        this.logPath = logPath || path.join(require('os').tmpdir(), 'claude-installer-progress.json');
        this.uiCallbacks = [];
        
        // Initialize progress state
        this.state = {
            phase: 'initialization',
            totalSteps: totalSteps,
            currentStep: 0,
            overallProgress: 0,
            currentOperation: 'Starting installation...',
            estimatedTimeRemaining: null,
            errors: [],
            warnings: []
        };
        
        this.saveState();
    }
    
    /**
     * Update progress with a new step
     * @param {string} stepName - Name of the current step
     * @param {string} status - Status: 'starting', 'in_progress', 'completed', 'failed', 'skipped'
     * @param {Object} details - Additional details about the step
     */
    updateProgress(stepName, status, details = {}) {
        const timestamp = new Date();
        const stepInfo = {
            name: stepName,
            status: status,
            timestamp: timestamp,
            details: details,
            stepNumber: this.currentStep + 1
        };
        
        // Update step count for completed/failed/skipped steps
        if (['completed', 'failed', 'skipped'].includes(status)) {
            this.currentStep++;
        }
        
        // Calculate progress percentage
        const progress = Math.min((this.currentStep / this.totalSteps) * 100, 100);
        
        // Add to step details
        this.stepDetails.push(stepInfo);
        
        // Update state
        this.state.currentStep = this.currentStep;
        this.state.overallProgress = progress;
        this.state.currentOperation = stepName;
        this.state.estimatedTimeRemaining = this.calculateTimeRemaining();
        
        // Handle errors and warnings
        if (status === 'failed' && details.error) {
            this.state.errors.push({
                step: stepName,
                error: details.error,
                timestamp: timestamp
            });
        }
        
        if (details.warning) {
            this.state.warnings.push({
                step: stepName,
                warning: details.warning,
                timestamp: timestamp
            });
        }
        
        // Save state and notify UI
        this.saveState();
        this.notifyUI(progress, stepName, status, details);
        
        // Log progress
        this.logProgress(stepInfo, progress);
        
        return stepInfo;
    }
    
    /**
     * Start a new phase of installation
     * @param {string} phaseName - Name of the phase
     * @param {number} phaseSteps - Number of steps in this phase
     */
    startPhase(phaseName, phaseSteps = null) {
        this.state.phase = phaseName;
        
        const stepInfo = this.updateProgress(`Starting ${phaseName}`, 'starting', {
            phase: phaseName,
            phaseSteps: phaseSteps
        });
        
        console.log(`\n🚀 Starting Phase: ${phaseName}`);
        if (phaseSteps) {
            console.log(`   Expected steps: ${phaseSteps}`);
        }
        
        return stepInfo;
    }
    
    /**
     * Complete a phase
     * @param {string} phaseName - Name of the phase
     * @param {Object} summary - Phase completion summary
     */
    completePhase(phaseName, summary = {}) {
        return this.updateProgress(`Completed ${phaseName}`, 'completed', {
            phase: phaseName,
            summary: summary,
            phaseDuration: this.getElapsedTime()
        });
    }
    
    /**
     * Register a UI callback for progress updates
     * @param {Function} callback - Function to call with progress updates
     */
    onProgress(callback) {
        if (typeof callback === 'function') {
            this.uiCallbacks.push(callback);
        }
    }
    
    /**
     * Notify all registered UI callbacks
     * @private
     */
    notifyUI(progress, stepName, status, details) {
        const updateData = {
            progress: progress,
            stepName: stepName,
            status: status,
            details: details,
            currentStep: this.currentStep,
            totalSteps: this.totalSteps,
            phase: this.state.phase,
            estimatedTimeRemaining: this.state.estimatedTimeRemaining
        };
        
        this.uiCallbacks.forEach(callback => {
            try {
                callback(updateData);
            } catch (error) {
                console.error('UI callback error:', error.message);
            }
        });
        
        // Also write to PowerShell-readable format for NSIS integration
        this.writePowerShellUpdate(updateData);
    }
    
    /**
     * Write progress update in PowerShell-readable format
     * @private
     */
    writePowerShellUpdate(updateData) {
        const psUpdatePath = path.join(require('os').tmpdir(), 'claude-installer-ps-update.json');
        
        try {
            fs.writeFileSync(psUpdatePath, JSON.stringify({
                timestamp: new Date().toISOString(),
                progress: updateData.progress,
                step: updateData.stepName,
                status: updateData.status,
                phase: updateData.phase,
                currentStep: updateData.currentStep,
                totalSteps: updateData.totalSteps,
                estimatedTimeRemaining: updateData.estimatedTimeRemaining,
                details: updateData.details
            }, null, 2));
        } catch (error) {
            // Silent fail - don't break installation for UI update issues
        }
    }
    
    /**
     * Calculate estimated time remaining
     * @private
     */
    calculateTimeRemaining() {
        if (this.currentStep === 0) return null;
        
        const elapsed = Date.now() - this.startTime.getTime();
        const avgTimePerStep = elapsed / this.currentStep;
        const remainingSteps = this.totalSteps - this.currentStep;
        
        return Math.round(avgTimePerStep * remainingSteps / 1000); // seconds
    }
    
    /**
     * Get elapsed time since start
     */
    getElapsedTime() {
        return Math.round((Date.now() - this.startTime.getTime()) / 1000); // seconds
    }
    
    /**
     * Save current state to file
     * @private
     */
    saveState() {
        try {
            const stateData = {
                ...this.state,
                stepDetails: this.stepDetails,
                startTime: this.startTime.toISOString(),
                lastUpdate: new Date().toISOString(),
                elapsedTime: this.getElapsedTime()
            };
            
            fs.writeFileSync(this.logPath, JSON.stringify(stateData, null, 2));
        } catch (error) {
            console.error('Failed to save progress state:', error.message);
        }
    }
    
    /**
     * Load state from file
     */
    static loadState(logPath = null) {
        const statePath = logPath || path.join(require('os').tmpdir(), 'claude-installer-progress.json');
        
        try {
            if (fs.existsSync(statePath)) {
                const stateData = JSON.parse(fs.readFileSync(statePath, 'utf8'));
                
                // Create new tracker with loaded state
                const tracker = new ProgressTracker(stateData.totalSteps, statePath);
                tracker.state = stateData;
                tracker.stepDetails = stateData.stepDetails || [];
                tracker.currentStep = stateData.currentStep || 0;
                tracker.startTime = new Date(stateData.startTime);
                
                return tracker;
            }
        } catch (error) {
            console.error('Failed to load progress state:', error.message);
        }
        
        return null;
    }
    
    /**
     * Log progress to console
     * @private
     */
    logProgress(stepInfo, progress) {
        const statusEmoji = {
            'starting': '🔄',
            'in_progress': '⏳',
            'completed': '✅',
            'failed': '❌',
            'skipped': '⏭️'
        };
        
        const emoji = statusEmoji[stepInfo.status] || '📍';
        const timeStr = this.formatElapsedTime();
        
        console.log(`${emoji} [${progress.toFixed(1)}%] ${stepInfo.name} (${timeStr})`);
        
        if (stepInfo.details.warning) {
            console.log(`   ⚠️  Warning: ${stepInfo.details.warning}`);
        }
        
        if (stepInfo.status === 'failed' && stepInfo.details.error) {
            console.log(`   💥 Error: ${stepInfo.details.error}`);
        }
    }
    
    /**
     * Format elapsed time as human readable string
     * @private
     */
    formatElapsedTime() {
        const seconds = this.getElapsedTime();
        if (seconds < 60) return `${seconds}s`;
        
        const minutes = Math.floor(seconds / 60);
        const remainingSeconds = seconds % 60;
        return `${minutes}m ${remainingSeconds}s`;
    }
    
    /**
     * Generate installation summary
     */
    generateSummary() {
        const completedSteps = this.stepDetails.filter(s => s.status === 'completed').length;
        const failedSteps = this.stepDetails.filter(s => s.status === 'failed').length;
        const skippedSteps = this.stepDetails.filter(s => s.status === 'skipped').length;
        const totalTime = this.formatElapsedTime();
        
        return {
            totalSteps: this.totalSteps,
            completedSteps: completedSteps,
            failedSteps: failedSteps,
            skippedSteps: skippedSteps,
            totalTime: totalTime,
            success: failedSteps === 0,
            errors: this.state.errors,
            warnings: this.state.warnings,
            stepDetails: this.stepDetails
        };
    }
    
    /**
     * Clean up progress files
     */
    cleanup() {
        try {
            if (fs.existsSync(this.logPath)) {
                fs.unlinkSync(this.logPath);
            }
            
            const psUpdatePath = path.join(require('os').tmpdir(), 'claude-installer-ps-update.json');
            if (fs.existsSync(psUpdatePath)) {
                fs.unlinkSync(psUpdatePath);
            }
        } catch (error) {
            console.error('Failed to cleanup progress files:', error.message);
        }
    }
}

module.exports = ProgressTracker;

// CLI usage example
if (require.main === module) {
    console.log('🧪 Testing Progress Tracking System');
    console.log('==================================\n');
    
    const tracker = new ProgressTracker(5);
    
    // Register UI callback
    tracker.onProgress((data) => {
        console.log(`   UI Update: ${data.progress.toFixed(1)}% - ${data.stepName}`);
    });
    
    // Simulate installation steps
    tracker.startPhase('System Validation', 2);
    tracker.updateProgress('Checking Windows version', 'completed', { version: '10.0.19041' });
    tracker.updateProgress('Checking admin rights', 'completed');
    
    tracker.startPhase('WSL2 Installation', 2);
    tracker.updateProgress('Enabling WSL features', 'completed');
    tracker.updateProgress('Installing WSL2 kernel', 'completed', { 
        warning: 'Reboot may be required' 
    });
    
    tracker.startPhase('Claude Code Setup', 1);
    tracker.updateProgress('Installing Claude Code CLI', 'completed');
    
    // Generate summary
    const summary = tracker.generateSummary();
    console.log('\n📊 Installation Summary:');
    console.log(`   Success: ${summary.success}`);
    console.log(`   Total time: ${summary.totalTime}`);
    console.log(`   Steps completed: ${summary.completedSteps}/${summary.totalSteps}`);
    console.log(`   Warnings: ${summary.warnings.length}`);
    
    tracker.cleanup();
}