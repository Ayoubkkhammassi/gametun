/**
 * Joueurs de démonstration (pour tester Game Match / Social Match avec du contenu).
 * NON destiné à la production. Lancer: npx ts-node prisma/demo-seed.ts
 */
import { PrismaClient, SkillLevel, PlayStyle } from '@prisma/client';
import * as argon2 from 'argon2';

const prisma = new PrismaClient();

interface DemoPlayer {
  pseudo: string;
  level: SkillLevel;
  playStyle: PlayStyle;
  games: string[];
  from: string;
  to: string;
  region: string;
}

const PLAYERS: DemoPlayer[] = [
  { pseudo: 'YASSINE', level: 'INTERMEDIATE', playStyle: 'TEAM_PLAYER', games: ['valorant', 'fortnite', 'fifa'], from: '20:00', to: '23:00', region: 'Tunis' },
  { pseudo: 'SKYZZ', level: 'INTERMEDIATE', playStyle: 'COMPETITIVE', games: ['valorant', 'cs2'], from: '19:00', to: '23:00', region: 'Sfax' },
  { pseudo: 'KLAY', level: 'ADVANCED', playStyle: 'STRATEGIST', games: ['valorant', 'league-of-legends'], from: '21:00', to: '23:30', region: 'Tunis' },
  { pseudo: 'LINA', level: 'INTERMEDIATE', playStyle: 'SUPPORT', games: ['valorant', 'minecraft'], from: '20:00', to: '22:30', region: 'Sousse' },
  { pseudo: 'MEHDI', level: 'BEGINNER', playStyle: 'CASUAL', games: ['minecraft', 'fortnite'], from: '18:00', to: '21:00', region: 'Tunis' },
  { pseudo: 'AMINE', level: 'ADVANCED', playStyle: 'AGGRESSIVE', games: ['minecraft', 'valorant', 'gta'], from: '20:00', to: '23:00', region: 'Tunis' },
  { pseudo: 'RANIA', level: 'INTERMEDIATE', playStyle: 'TEAM_PLAYER', games: ['fifa', 'rocket-league'], from: '19:30', to: '22:00', region: 'Bizerte' },
  { pseudo: 'FIRAS', level: 'EXPERT', playStyle: 'COMPETITIVE', games: ['valorant', 'cs2', 'apex-legends'], from: '21:00', to: '23:59', region: 'Tunis' },
];

async function main(): Promise<void> {
  console.log('🌱 Création des joueurs de démo...');
  const passwordHash = await argon2.hash('demo1234');

  for (const p of PLAYERS) {
    const email = `${p.pseudo.toLowerCase()}@demo.gametun.tn`;
    // Date de naissance ~ 18-22 ans.
    const birthDate = new Date(2004, 3, 15);

    const games = await prisma.game.findMany({
      where: { slug: { in: p.games } },
      select: { id: true },
    });

    await prisma.user.upsert({
      where: { email },
      update: {},
      create: {
        email,
        pseudo: p.pseudo,
        passwordHash,
        birthDate,
        language: 'FR',
        region: p.region,
        isOnline: true,
        lastSeenAt: new Date(),
        profile: {
          create: {
            level: p.level,
            playStyle: p.playStyle,
            availabilityFrom: p.from,
            availabilityTo: p.to,
            bio: `Joueur ${p.region} — dispo ${p.from}-${p.to}. Toujours prêt pour une game !`,
          },
        },
        statistics: { create: { matchesPlayed: 40, wins: 26 } },
        games: {
          create: games.map((g) => ({ gameId: g.id, level: p.level })),
        },
      },
    });
    console.log(`  ✅ ${p.pseudo}`);
  }
  const count = await prisma.user.count();
  console.log(`✅ Terminé. ${count} utilisateurs en base.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
