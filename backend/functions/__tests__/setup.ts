/**
 * Katuya Test Setup
 * by Silvio Lionel Nieva
 */

// Silence console during tests unless explicitly needed
global.console = {
  ...console,
  debug: jest.fn(),
  log: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
};
