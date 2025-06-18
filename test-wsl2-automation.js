#!/usr/bin/env node
/**
 * Simple test script to validate WSL2 installation automation
 * This can be run in development to test the WSL2 components
 */

const DependencyDetector = require('./src/scripts/validation/dependency-detector');

console.log('🧪 Testing WSL2 Installation Automation');
console.log('========================================\n');

async function testWSL2Components() {
    const detector = new DependencyDetector();
    
    console.log('1. Testing dependency detection...');
    try {
        const results = await detector.detectAll();
        
        console.log('\n📊 Detection Results:');
        console.log('---------------------');
        
        for (const [dep, result] of Object.entries(results)) {
            const config = detector.dependencies[dep];
            const status = result.installed ? 
                (result.compatible ? '✅' : '⚠️ ') : '❌';
            
            console.log(`${status} ${config.name}`);
            console.log(`   Installed: ${result.installed}`);
            if (result.version) {
                console.log(`   Version: ${result.version}`);
            }
            if (result.location) {
                console.log(`   Location: ${result.location}`);
            }
            console.log(`   Should Install: ${result.shouldInstall}`);
            console.log('');
        }
        
        console.log('\n2. Testing summary generation...');
        console.log(detector.generateSummary());
        
        console.log('\n✅ WSL2 automation components tested successfully!');
        console.log('\n📝 Next Steps:');
        console.log('   - Test PowerShell module with: Import-Module src/scripts/powershell/ClaudeCodeInstaller.psm1');
        console.log('   - Test WSL2 prerequisites: Test-WSL2Prerequisites');
        console.log('   - Test installation state management: Get-InstallationState');
        
    } catch (error) {
        console.error('❌ Error testing WSL2 components:', error.message);
        process.exit(1);
    }
}

// Run tests
testWSL2Components().catch(console.error);