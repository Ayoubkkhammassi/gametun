import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const GAMES = [
  { slug: 'valorant', name: 'Valorant', category: 'FPS' },
  { slug: 'fortnite', name: 'Fortnite', category: 'Battle Royale' },
  { slug: 'minecraft', name: 'Minecraft', category: 'Sandbox' },
  { slug: 'fifa', name: 'EA SPORTS FC (FIFA)', category: 'Sport' },
  { slug: 'league-of-legends', name: 'League of Legends', category: 'MOBA' },
  { slug: 'cs2', name: 'Counter-Strike 2', category: 'FPS' },
  { slug: 'call-of-duty', name: 'Call of Duty', category: 'FPS' },
  { slug: 'rocket-league', name: 'Rocket League', category: 'Sport' },
  { slug: 'apex-legends', name: 'Apex Legends', category: 'Battle Royale' },
  { slug: 'pubg', name: 'PUBG', category: 'Battle Royale' },
  { slug: 'free-fire', name: 'Free Fire', category: 'Battle Royale' },
  { slug: 'clash-royale', name: 'Clash Royale', category: 'Stratégie' },
  { slug: 'gta', name: 'GTA Online', category: 'Action' },
  { slug: 'dota2', name: 'Dota 2', category: 'MOBA' },
];

async function main(): Promise<void> {
  console.log('🌱 Seed des jeux...');
  for (const game of GAMES) {
    await prisma.game.upsert({
      where: { slug: game.slug },
      update: { name: game.name, category: game.category },
      create: game,
    });
  }
  const count = await prisma.game.count();
  console.log(`✅ ${count} jeux en base.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
