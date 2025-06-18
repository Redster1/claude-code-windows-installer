/**
 * Unit tests for the DependencyDetector class
 */

const DependencyDetector = require('../../scripts/validation/dependency-detector');

// Mock child_process and util
jest.mock('child_process', () => ({
  exec: jest.fn()
}));

jest.mock('util', () => ({
  promisify: jest.fn((fn) => {
    return (...args) => {
      return new Promise((resolve, reject) => {
        fn(...args, (error, stdout, stderr) => {
          if (error) {
            reject(error);
          } else {
            resolve({ stdout, stderr });
          }
        });
      });
    };
  })
}));

describe('DependencyDetector', () => {
  let detector;
  let mockExec;

  beforeEach(() => {
    detector = new DependencyDetector();
    mockExec = require('child_process').exec;
    jest.clearAllMocks();
  });

  describe('constructor', () => {
    test('initializes with correct dependencies', () => {
      expect(detector.dependencies).toHaveProperty('wsl2');
      expect(detector.dependencies).toHaveProperty('nodejs');
      expect(detector.dependencies).toHaveProperty('git');
      expect(detector.dependencies).toHaveProperty('curl');
      expect(detector.dependencies).toHaveProperty('claude');
    });

    test('sets minimum version requirements', () => {
      expect(detector.dependencies.wsl2.minVersion).toBe('2.0.0');
      expect(detector.dependencies.nodejs.minVersion).toBe('18.0.0');
      expect(detector.dependencies.git.minVersion).toBe('2.30.0');
    });
  });

  describe('compareVersions', () => {
    test('correctly compares semantic versions', () => {
      expect(detector.compareVersions('2.0.0', '1.0.0')).toBe(1);
      expect(detector.compareVersions('1.0.0', '2.0.0')).toBe(-1);
      expect(detector.compareVersions('1.0.0', '1.0.0')).toBe(0);
      expect(detector.compareVersions('1.0.1', '1.0.0')).toBe(1);
      expect(detector.compareVersions('1.1.0', '1.0.9')).toBe(1);
    });

    test('handles version strings with different lengths', () => {
      expect(detector.compareVersions('1.0', '1.0.0')).toBe(0);
      expect(detector.compareVersions('1.0.0', '1.0')).toBe(0);
      expect(detector.compareVersions('1.0.1', '1.0')).toBe(1);
    });
  });

  describe('detectWSL2', () => {
    test('detects WSL2 when installed', async () => {
      // Mock successful WSL2 detection
      mockExec
        .mockImplementationOnce((cmd, options, callback) => {
          if (cmd.includes('wsl --status')) {
            callback(null, { stdout: 'WSL version: 2.0.9.0' }, '');
          }
        })
        .mockImplementationOnce((cmd, options, callback) => {
          if (cmd.includes('wsl --version')) {
            callback(null, { stdout: 'WSL version: 2.0.9.0' }, '');
          }
        })
        .mockImplementationOnce((cmd, options, callback) => {
          if (cmd.includes('wsl --list --verbose')) {
            callback(null, { stdout: '* Alpine    Running    2' }, '');
          }
        });

      const result = await detector.detectWSL2({ minVersion: '2.0.0' });

      expect(result.installed).toBe(true);
      expect(result.version).toBe('2.0.9.0');
      expect(result.compatible).toBe(true);
      expect(result.shouldInstall).toBe(false);
    });

    test('handles WSL2 not installed', async () => {
      // Mock WSL2 not found
      mockExec.mockImplementation((cmd, options, callback) => {
        callback(new Error('Command not found'), null, 'wsl: command not found');
      });

      const result = await detector.detectWSL2({ minVersion: '2.0.0' });

      expect(result.installed).toBe(false);
      expect(result.version).toBe(null);
      expect(result.compatible).toBe(false);
      expect(result.shouldInstall).toBe(true);
    });
  });

  describe('detectNodeJS', () => {
    test('detects Node.js on Windows', async () => {
      // Mock Node.js found on Windows
      mockExec
        .mockImplementationOnce((cmd, options, callback) => {
          if (cmd.includes('node --version') && options.shell === 'powershell.exe') {
            callback(null, { stdout: 'v20.11.0' }, '');
          }
        })
        .mockImplementationOnce((cmd, options, callback) => {
          if (cmd.includes('wsl -- node --version')) {
            callback(new Error('Not found'), null, '');
          }
        });

      const result = await detector.detectNodeJS({ minVersion: '18.0.0' });

      expect(result.installed).toBe(true);
      expect(result.version).toBe('20.11.0');
      expect(result.compatible).toBe(true);
      expect(result.shouldInstall).toBe(false);
      expect(result.location).toBe('Windows');
    });

    test('detects Node.js in WSL when not on Windows', async () => {
      // Mock Node.js not found on Windows but found in WSL
      mockExec.mockImplementation((cmd, options, callback) => {
        if (cmd.includes('node --version') && options && options.shell === 'powershell.exe') {
          callback(new Error('Not found'), null, '');
        } else if (cmd.includes('wsl -- node --version')) {
          callback(null, { stdout: 'v18.19.0' }, '');
        } else {
          callback(new Error('Command not found'), null, '');
        }
      });

      const result = await detector.detectNodeJS({ minVersion: '18.0.0' });

      expect(result.installed).toBe(true);
      expect(result.version).toBe('18.19.0');
      expect(result.compatible).toBe(true);
      expect(result.shouldInstall).toBe(false);
      expect(result.location).toBe('WSL');
    });

    test('handles no Node.js installation found', async () => {
      // Mock Node.js not found anywhere
      mockExec.mockImplementation((cmd, options, callback) => {
        callback(new Error('Not found'), null, '');
      });

      const result = await detector.detectNodeJS({ minVersion: '18.0.0' });

      expect(result.installed).toBe(false);
      expect(result.version).toBe(null);
      expect(result.compatible).toBe(false);
      expect(result.shouldInstall).toBe(true);
      expect(result.location).toBe('None');
    });
  });

  describe('detectClaudeCode', () => {
    test('detects Claude Code when installed', async () => {
      // Mock Claude Code found
      mockExec.mockImplementationOnce((cmd, options, callback) => {
        if (cmd.includes('claude --version')) {
          callback(null, { stdout: '1.2.3' }, '');
        }
      });

      const result = await detector.detectClaudeCode({ minVersion: '1.0.0' });

      expect(result.installed).toBe(true);
      expect(result.version).toBe('1.2.3');
      expect(result.compatible).toBe(true);
      expect(result.shouldInstall).toBe(false);
    });

    test('handles Claude Code not installed', async () => {
      // Mock Claude Code not found
      mockExec.mockImplementation((cmd, options, callback) => {
        callback(new Error('Command not found'), null, '');
      });

      const result = await detector.detectClaudeCode({ minVersion: '1.0.0' });

      expect(result.installed).toBe(false);
      expect(result.version).toBe(null);
      expect(result.compatible).toBe(false);
      expect(result.shouldInstall).toBe(true);
    });
  });

  describe('parseWSLDistributions', () => {
    test('parses WSL distribution list correctly', () => {
      const output = `  NAME            STATE           VERSION
* Alpine          Running         2
  Ubuntu          Stopped         2
  Debian          Running         1`;

      const result = detector.parseWSLDistributions(output);

      expect(result).toHaveLength(3);
      expect(result[0]).toEqual({
        name: 'Alpine',
        default: true,
        state: 'Running',
        version: '2'
      });
      expect(result[1]).toEqual({
        name: 'Ubuntu',
        default: false,
        state: 'Stopped',
        version: '2'
      });
    });

    test('handles empty distribution list', () => {
      const result = detector.parseWSLDistributions('');
      expect(result).toHaveLength(0);
    });
  });

  describe('generateSummary', () => {
    test('generates summary when results available', async () => {
      // Mock successful detection results
      detector.results = {
        wsl2: {
          installed: true,
          version: '2.0.9.0',
          compatible: true,
          shouldInstall: false
        },
        nodejs: {
          installed: false,
          version: null,
          compatible: false,
          shouldInstall: true
        }
      };

      const summary = detector.generateSummary();

      expect(summary).toContain('Dependency Detection Summary');
      expect(summary).toContain('✅ Windows Subsystem for Linux 2');
      expect(summary).toContain('❌ Node.js');
      expect(summary).toContain('Components to install: 1/2');
    });

    test('handles no results available', () => {
      const summary = detector.generateSummary();
      expect(summary).toContain('No dependency detection results available');
    });
  });

  describe('detectAll', () => {
    test('detects all dependencies and returns comprehensive results', async () => {
      // Mock all detections
      mockExec.mockImplementation((cmd, options, callback) => {
        // Mock successful responses for all tools
        if (cmd.includes('wsl --status')) {
          callback(null, { stdout: 'WSL version: 2.0.9.0' }, '');
        } else if (cmd.includes('node --version')) {
          callback(null, { stdout: 'v20.11.0' }, '');
        } else if (cmd.includes('git --version')) {
          callback(null, { stdout: 'git version 2.40.0' }, '');
        } else if (cmd.includes('curl --version')) {
          callback(null, { stdout: 'curl 8.0.0' }, '');
        } else if (cmd.includes('claude --version')) {
          callback(new Error('Not found'), null, '');
        } else {
          callback(null, { stdout: '' }, '');
        }
      });

      const results = await detector.detectAll();

      expect(results).toHaveProperty('wsl2');
      expect(results).toHaveProperty('nodejs');
      expect(results).toHaveProperty('git');
      expect(results).toHaveProperty('curl');
      expect(results).toHaveProperty('claude');

      // Claude should need installation
      expect(results.claude.shouldInstall).toBe(true);
    });
  });
});