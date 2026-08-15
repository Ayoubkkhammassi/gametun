import { ageGroup, computeAge, toPublicUser } from './privacy.util';
import { User } from '@prisma/client';

describe('privacy.util', () => {
  describe('computeAge', () => {
    it('calcule l\'âge en années révolues', () => {
      const now = new Date('2026-08-14');
      expect(computeAge(new Date('2000-08-14'), now)).toBe(26);
      expect(computeAge(new Date('2000-08-15'), now)).toBe(25); // anniversaire non atteint
      expect(computeAge(new Date('2010-01-01'), now)).toBe(16);
    });
  });

  describe('ageGroup', () => {
    it('renvoie la bonne tranche', () => {
      expect(ageGroup(14)).toBe('13-15');
      expect(ageGroup(17)).toBe('16-17');
      expect(ageGroup(19)).toBe('18-24');
      expect(ageGroup(30)).toBe('25-34');
      expect(ageGroup(40)).toBe('35+');
    });
  });

  describe('toPublicUser', () => {
    it('n\'expose jamais la date de naissance ni le mot de passe', () => {
      const user = {
        id: 'u1',
        email: 'a@b.com',
        passwordHash: 'secret-hash',
        pseudo: 'AYOUB',
        birthDate: new Date('2005-01-01'),
        language: 'FR',
        region: 'Tunisie',
        avatarUrl: null,
        role: 'USER',
        status: 'ACTIVE',
        isPremium: false,
        isOnline: true,
        lastSeenAt: null,
        refreshTokenHash: 'r-hash',
        createdAt: new Date('2026-01-01'),
        updatedAt: new Date('2026-01-01'),
      } as unknown as User;

      const pub = toPublicUser(user) as Record<string, unknown>;
      expect(pub.pseudo).toBe('AYOUB');
      expect(pub.ageGroup).toBeDefined();
      expect(pub.birthDate).toBeUndefined();
      expect(pub.passwordHash).toBeUndefined();
      expect(pub.refreshTokenHash).toBeUndefined();
      expect(pub.email).toBeUndefined();
    });
  });
});
