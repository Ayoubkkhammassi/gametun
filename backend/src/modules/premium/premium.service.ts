import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NotificationType, SubscriptionStatus } from '@prisma/client';
import { AppConfig } from '../../config/configuration';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class PremiumService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService<AppConfig, true>,
    private readonly notifications: NotificationsService,
  ) {}

  /** Présentation honnête Free vs Premium (spec §16). */
  plans() {
    const price = this.config.get('premiumPriceTnd', { infer: true });
    return {
      free: {
        name: 'Gratuit',
        features: [
          'Profil joueur',
          'Recherche normale',
          'Game Match',
          'Chat',
          'Squad',
          'Mini-jeux',
          'Statistiques de base',
        ],
      },
      premium: {
        name: 'Premium',
        priceTnd: price,
        period: 'mois',
        note: 'Annulable à tout moment. Aucun avantage de triche en jeu.',
        features: [
          'Smart Squad avancé',
          'Filtres avancés',
          'Priority Match',
          'Boost de profil',
          'Personnalisation Premium',
          'Statistiques avancées',
          'Badges Premium',
          'Fonctionnalités avancées de Squad',
        ],
      },
    };
  }

  async status(userId: string) {
    const sub = await this.prisma.subscription.findUnique({ where: { userId } });
    const active =
      sub?.status === SubscriptionStatus.ACTIVE &&
      (!sub.expiresAt || sub.expiresAt > new Date());
    return {
      isPremium: !!active,
      status: sub?.status ?? 'NONE',
      expiresAt: sub?.expiresAt ?? null,
      plan: sub?.plan ?? null,
    };
  }

  /**
   * Active un abonnement. NOTE: l'intégration de paiement réelle se fait
   * côté serveur via un fournisseur (webhook), jamais dans l'app mobile.
   * Ici on prépare l'abonnement en attente d'un vrai flux de paiement.
   */
  async subscribe(userId: string) {
    const price = this.config.get('premiumPriceTnd', { infer: true });
    const now = new Date();
    const expires = new Date(now);
    expires.setMonth(expires.getMonth() + 1);

    const sub = await this.prisma.subscription.upsert({
      where: { userId },
      update: {
        status: SubscriptionStatus.ACTIVE,
        startedAt: now,
        expiresAt: expires,
        priceTnd: price,
      },
      create: {
        userId,
        plan: 'premium_monthly',
        status: SubscriptionStatus.ACTIVE,
        startedAt: now,
        expiresAt: expires,
        priceTnd: price,
      },
    });
    await this.prisma.user.update({
      where: { id: userId },
      data: { isPremium: true },
    });
    await this.notifications.create({
      userId,
      type: NotificationType.PREMIUM,
      title: 'Bienvenue Premium ⭐',
      body: 'Toutes les fonctionnalités avancées sont débloquées.',
    });
    return sub;
  }

  async cancel(userId: string) {
    await this.prisma.subscription.updateMany({
      where: { userId },
      data: { status: SubscriptionStatus.CANCELLED },
    });
    await this.prisma.user.update({
      where: { id: userId },
      data: { isPremium: false },
    });
    return { cancelled: true };
  }
}
