import { compatibilityScore, MatchCriteria } from './compatibility';

describe('compatibilityScore', () => {
  const baseCriteria: MatchCriteria & { region?: string } = {
    gameSlugs: ['valorant'],
    level: 'INTERMEDIATE',
    language: 'FR',
    availabilityFrom: '20:00',
    availabilityTo: '23:00',
    region: 'Tunisie',
  };

  it('donne un score élevé pour un profil très compatible', () => {
    const score = compatibilityScore(baseCriteria, {
      gameSlugs: ['valorant', 'fortnite'],
      level: 'INTERMEDIATE',
      language: 'FR',
      region: 'Tunisie',
      availabilityFrom: '20:00',
      availabilityTo: '23:00',
    });
    expect(score).toBeGreaterThanOrEqual(90);
  });

  it('donne un score plus bas pour un profil peu compatible', () => {
    const score = compatibilityScore(baseCriteria, {
      gameSlugs: ['minecraft'], // aucun jeu commun
      level: 'EXPERT',
      language: 'EN',
      region: 'France',
      availabilityFrom: '08:00',
      availabilityTo: '10:00',
    });
    expect(score).toBeLessThan(40);
  });

  it('reste borné entre 0 et 100', () => {
    const score = compatibilityScore(baseCriteria, {
      gameSlugs: [],
      level: 'BEGINNER',
      language: 'AR',
      region: '',
      availabilityFrom: null,
      availabilityTo: null,
    });
    expect(score).toBeGreaterThanOrEqual(0);
    expect(score).toBeLessThanOrEqual(100);
  });
});
