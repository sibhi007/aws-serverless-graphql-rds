import { describe, it, expect } from 'vitest';
import { cleanName } from './dbResolver';

describe('cleanName', () => {
  it('trims valid input', () => expect(cleanName('  book  ')).toBe('book'));
  it('rejects empty input', () => expect(() => cleanName('   ')).toThrow());
  it('rejects over-long input', () => expect(() => cleanName('x'.repeat(101))).toThrow());
});
