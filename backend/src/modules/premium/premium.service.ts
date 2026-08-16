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
      // Paiement manuel via D17.
      payment: {
        method: 'D17',
        number: this.config.get('d17Number', { infer: true }),
        priceTnd: price,
        instructions:
          'Envoie le montant via D17 au numéro ci-dessus, puis saisis la ' +
          'référence du virement. Ton Premium sera activé après validation.',
      },
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

  // ---- Paiement manuel D17 (demande + validation admin) ------------------

  /** L'utilisateur soumet une preuve de paiement D17. */
  async createRequest(userId: string, reference: string) {
    const req = await this.prisma.premiumRequest.create({
      data: { userId, reference: reference.trim(), method: 'D17' },
    });
    // Notifie les admins qu'une demande est en attente.
    const admins = await this.prisma.user.findMany({
      where: { role: 'ADMIN' },
      select: { id: true },
    });
    await Promise.all(
      admins.map((a) =>
        this.notifications.create({
          userId: a.id,
          type: NotificationType.PREMIUM,
          title: 'Nouvelle demande Premium 💳',
          body: `Paiement D17 à valider (réf: ${reference.trim()}).`,
          data: { requestId: req.id },
        }),
      ),
    );
    return req;
  }

  /** Dernière demande de l'utilisateur (pour afficher son statut). */
  async myLatestRequest(userId: string) {
    return this.prisma.premiumRequest.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  /** [ADMIN] Liste des demandes en attente. */
  async listPendingRequests() {
    const rows = await this.prisma.premiumRequest.findMany({
      where: { status: 'PENDING' },
      include: {
        user: { select: { id: true, pseudo: true, email: true, avatarUrl: true } },
      },
      orderBy: { createdAt: 'asc' },
    });
    return rows;
  }

  /** [ADMIN] Valide une demande → active le Premium de l'utilisateur. */
  async approveRequest(requestId: string) {
    const req = await this.prisma.premiumRequest.update({
      where: { id: requestId },
      data: { status: 'APPROVED' },
    });
    await this.subscribe(req.userId);
    return { approved: true };
  }

  /** [ADMIN] Rejette une demande. */
  async rejectRequest(requestId: string) {
    const req = await this.prisma.premiumRequest.update({
      where: { id: requestId },
      data: { status: 'REJECTED' },
    });
    await this.notifications.create({
      userId: req.userId,
      type: NotificationType.PREMIUM,
      title: 'Demande Premium refusée',
      body: 'Ton paiement n\'a pas pu être vérifié. Contacte le support.',
    });
    return { rejected: true };
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
