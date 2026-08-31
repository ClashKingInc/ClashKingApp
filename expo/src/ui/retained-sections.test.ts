import { retainRecentSections } from './retained-sections';

describe('retainRecentSections', () => {
  it('keeps the active and immediately previous section without retaining every heavy page', () => {
    expect(retainRecentSections(['home'], 'history')).toEqual(['history', 'home']);
    expect(retainRecentSections(['history', 'home'], 'cwl')).toEqual(['cwl', 'history']);
    expect(retainRecentSections(['cwl', 'history'], 'history')).toEqual(['history', 'cwl']);
  });
});
