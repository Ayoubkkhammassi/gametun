/**
 * Passe un utilisateur en ADMIN. Usage :
 *   npx ts-node prisma/make-admin.ts email@exemple.com
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const email = process.argv[2]?.toLowerCase();
  if (!email) {
    console.error('Usage: ts-node prisma/make-admin.ts <email>');
    process.exit(1);
  }
  const user = await prisma.user.update({
    where: { email },
    data: { role: 'ADMIN' },
    select: { id: true, pseudo: true, email: true, role: true },
  });
  console.log('✅ Admin:', user);
}

main()
  .catch((e) => {
    console.error('Erreur (email introuvable ?):', e.message);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
