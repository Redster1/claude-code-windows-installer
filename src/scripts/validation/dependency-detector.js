/**
 * Claude Code Windows Installer - Dependency Detection System
 * 
 * This module detects existing installations of WSL2, Node.js, Git, Curl, and Claude Code
 * to determine what needs to be installed vs what can be reused.
 */

const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

class DependencyDetector {
  constructor() {
    this.dependencies = {
      wsl2: { 
        minVersion: '2.0.0', 
        required: true,
        name: 'Windows Subsystem for Linux 2'
      },
      nodejs: { 
        minVersion: '18.0.0', 
        required: false,
        name: 'Node.js'
      },
      git: { 
        minVersion: '2.30.0', 
        required: false,
        name: 'Git'
      },
      curl: { 
        minVersion: '7.70.0', 
        required: false,
        name: 'Curl'
      },
      claude: {
        minVersion: '0.0.1',
        required: false,
        name: 'Claude Code CLI'
      }
    };
    
    this.results = {};
  }

  /**
   * Detect all dependencies and return comprehensive results
   * @returns {Promise<Object>} Detection results for all dependencies
   */
  async detectAll() {
    console.log('🔍 Starting dependency detection...');
    
    const results = {};
    
    for (const [dep, config] of Object.entries(this.dependencies)) {
      try {
        console.log(`   Checking ${config.name}...`);
        results[dep] = await this.detect(dep, config);
      } catch (error) {
        results[dep] = {
          installed: false,
          error: error.message,
          compatible: false,
          shouldInstall: true
        };
      }
    }
    
    this.results = results;
    return results;
  }

  /**
   * Detect a specific dependency
   * @param {string} dependency - The dependency to detect
   * @param {Object} config - Configuration for the dependency
   * @returns {Promise<Object>} Detection result
   */
  async detect(dependency, config) {
    switch (dependency) {
      case 'wsl2':
        return await this.detectWSL2(config);
      case 'nodejs':
        return await this.detectNodeJS(config);
      case 'git':
        return await this.detectGit(config);
      case 'curl':
        return await this.detectCurl(config);
      case 'claude':
        return await this.detectClaudeCode(config);
      default:
        throw new Error(`Unknown dependency: ${dependency}`);
    }
  }

  /**
   * Detect WSL2 installation and version
   */
  async detectWSL2(config) {
    try {
      // Check if WSL is available
      const { stdout: statusOutput } = await execAsync('wsl --status 2>nul', { 
        shell: 'powershell.exe' 
      });
      
      // Check WSL version
      const { stdout: versionOutput } = await execAsync('wsl --version 2>nul', { 
        shell: 'powershell.exe' 
      });
      
      const versionMatch = versionOutput.match(/WSL version: ([\d\.]+)/);
      const version = versionMatch ? versionMatch[1] : null;
      
      // Check for existing distributions
      const { stdout: listOutput } = await execAsync('wsl --list --verbose 2>nul', {
        shell: 'powershell.exe'
      });
      
      const distributions = this.parseWSLDistributions(listOutput);
      
      const compatible = version && this.compareVersions(version, config.minVersion) >= 0;
      
      return {
        installed: true,
        version: version,
        compatible: compatible,
        shouldInstall: !compatible,
        distributions: distributions,
        details: {
          hasAlpine: distributions.some(d => d.name.toLowerCase().includes('alpine')),
          defaultVersion: distributions.find(d => d.default)?.version || 'Unknown'
        }
      };
      
    } catch (error) {
      return {
        installed: false,
        version: null,
        compatible: false,
        shouldInstall: true,
        error: 'WSL not found or not accessible',
        distributions: []
      };
    }
  }

  /**
   * Detect Node.js installation (both Windows and WSL)
   */
  async detectNodeJS(config) {
    const results = {
      windows: null,
      wsl: null
    };
    
    // Check Windows Node.js
    try {
      const { stdout: winVersion } = await execAsync('node --version 2>nul', {
        shell: 'powershell.exe'
      });
      results.windows = {
        version: winVersion.trim().replace('v', ''),
        installed: true
      };
    } catch (error) {
      results.windows = { installed: false };
    }
    
    // Check WSL Node.js
    try {
      const { stdout: wslVersion } = await execAsync('wsl -- node --version 2>/dev/null');
      results.wsl = {
        version: wslVersion.trim().replace('v', ''),
        installed: true
      };
    } catch (error) {
      results.wsl = { installed: false };
    }
    
    // Determine best available version
    const windowsCompatible = results.windows.installed && 
      this.compareVersions(results.windows.version, config.minVersion) >= 0;
    const wslCompatible = results.wsl.installed && 
      this.compareVersions(results.wsl.version, config.minVersion) >= 0;
    
    const bestVersion = windowsCompatible ? results.windows.version : 
                       wslCompatible ? results.wsl.version : null;
    
    return {
      installed: results.windows.installed || results.wsl.installed,
      version: bestVersion,
      compatible: windowsCompatible || wslCompatible,
      shouldInstall: !windowsCompatible && !wslCompatible,
      details: results,
      location: windowsCompatible ? 'Windows' : wslCompatible ? 'WSL' : 'None'
    };
  }

  /**
   * Detect Git installation
   */
  async detectGit(config) {
    return await this.detectGenericTool('git', '--version', /git version ([\d\.]+)/, config);
  }

  /**
   * Detect Curl installation
   */
  async detectCurl(config) {
    return await this.detectGenericTool('curl', '--version', /curl ([\d\.]+)/, config);
  }

  /**
   * Detect Claude Code CLI installation
   */
  async detectClaudeCode(config) {
    try {
      // Try Windows first
      let version = null;
      let location = null;
      
      try {
        const { stdout: winOutput } = await execAsync('claude --version 2>nul', {
          shell: 'powershell.exe'
        });
        const winMatch = winOutput.match(/([\d\.]+)/);
        if (winMatch) {
          version = winMatch[1];
          location = 'Windows';
        }
      } catch (error) {
        // Try WSL
        try {
          const { stdout: wslOutput } = await execAsync('wsl -- claude --version 2>/dev/null');
          const wslMatch = wslOutput.match(/([\d\.]+)/);
          if (wslMatch) {
            version = wslMatch[1];
            location = 'WSL';
          }
        } catch (wslError) {
          // Not found in either location
        }
      }
      
      if (version) {
        const compatible = this.compareVersions(version, config.minVersion) >= 0;
        return {
          installed: true,
          version: version,
          compatible: compatible,
          shouldInstall: false, // Never reinstall Claude Code if found
          location: location
        };
      } else {
        return {
          installed: false,
          version: null,
          compatible: false,
          shouldInstall: true,
          location: 'None'
        };
      }
      
    } catch (error) {
      return {
        installed: false,
        version: null,
        compatible: false,
        shouldInstall: true,
        error: error.message
      };
    }
  }

  /**
   * Generic tool detection helper
   */
  async detectGenericTool(command, versionFlag, versionRegex, config) {
    try {
      const { stdout } = await execAsync(`${command} ${versionFlag} 2>nul`, {
        shell: 'powershell.exe'
      });
      
      const match = stdout.match(versionRegex);
      const version = match ? match[1] : null;
      
      if (version) {
        const compatible = this.compareVersions(version, config.minVersion) >= 0;
        return {
          installed: true,
          version: version,
          compatible: compatible,
          shouldInstall: !compatible
        };
      }
    } catch (error) {
      // Tool not found or error occurred
    }
    
    return {
      installed: false,
      version: null,
      compatible: false,
      shouldInstall: true
    };
  }

  /**
   * Parse WSL distribution list output
   */
  parseWSLDistributions(output) {
    const lines = output.split('\n').filter(line => line.trim());
    const distributions = [];
    
    for (const line of lines) {
      if (line.includes('NAME') || line.includes('---')) continue;
      
      // Handle the case where * indicates default distribution
      const cleanLine = line.trim();
      const isDefault = cleanLine.startsWith('*');
      const workingLine = cleanLine.replace(/^\*\s*/, '');
      
      const parts = workingLine.split(/\s+/);
      if (parts.length >= 3) {
        distributions.push({
          name: parts[0].trim(),
          default: isDefault,
          state: parts[1],
          version: parts[2]
        });
      }
    }
    
    return distributions;
  }

  /**
   * Compare semantic versions
   * @param {string} version1 - First version
   * @param {string} version2 - Second version
   * @returns {number} -1 if version1 < version2, 0 if equal, 1 if version1 > version2
   */
  compareVersions(version1, version2) {
    const v1parts = version1.split('.').map(Number);
    const v2parts = version2.split('.').map(Number);
    
    const maxLength = Math.max(v1parts.length, v2parts.length);
    
    for (let i = 0; i < maxLength; i++) {
      const v1part = v1parts[i] || 0;
      const v2part = v2parts[i] || 0;
      
      if (v1part < v2part) return -1;
      if (v1part > v2part) return 1;
    }
    
    return 0;
  }

  /**
   * Generate installation summary
   */
  generateSummary() {
    if (!this.results || Object.keys(this.results).length === 0) {
      return 'No dependency detection results available. Run detectAll() first.';
    }
    
    let summary = '\n📋 Dependency Detection Summary\n';
    summary += '================================\n\n';
    
    for (const [dep, result] of Object.entries(this.results)) {
      const config = this.dependencies[dep];
      const status = result.installed ? 
        (result.compatible ? '✅' : '⚠️ ') : '❌';
      
      summary += `${status} ${config.name}\n`;
      
      if (result.installed) {
        summary += `   Version: ${result.version || 'Unknown'}\n`;
        if (result.location) {
          summary += `   Location: ${result.location}\n`;
        }
        summary += `   Status: ${result.compatible ? 'Compatible' : 'Needs upgrade'}\n`;
      } else {
        summary += `   Status: Not installed\n`;
      }
      
      summary += `   Action: ${result.shouldInstall ? 'Will install' : 'Will use existing'}\n`;
      
      if (result.error) {
        summary += `   Error: ${result.error}\n`;
      }
      
      summary += '\n';
    }
    
    // Calculate estimated installation time
    const installSteps = Object.values(this.results).filter(r => r.shouldInstall).length;
    const estimatedMinutes = Math.max(2, installSteps * 2);
    
    summary += `⏱️  Estimated installation time: ${estimatedMinutes}-${estimatedMinutes + 3} minutes\n`;
    summary += `📦 Components to install: ${installSteps}/${Object.keys(this.results).length}\n`;
    
    return summary;
  }
}

module.exports = DependencyDetector;

// CLI usage
if (require.main === module) {
  const detector = new DependencyDetector();
  
  detector.detectAll()
    .then(results => {
      console.log(detector.generateSummary());
      process.exit(0);
    })
    .catch(error => {
      console.error('❌ Dependency detection failed:', error.message);
      process.exit(1);
    });
}