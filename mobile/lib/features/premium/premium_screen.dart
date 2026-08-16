import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_button.dart';
import '../../core/widgets/gt_scaffold.dart';
import '../../core/widgets/gt_text_field.dart';

final premiumPlansProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final data = await ref.read(apiClientProvider).get('/premium/plans');
  return data as Map<String, dynamic>;
});

final premiumStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final data = await ref.read(apiClientProvider).get('/premium/status');
  return data as Map<String, dynamic>;
});

final myPremiumRequestProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final data = await ref.read(apiClientProvider).get('/premium/request/mine');
  return data as Map<String, dynamic>?;
});

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(premiumPlansProvider);
    final status = ref.watch(premiumStatusProvider);
    final myReq = ref.watch(myPremiumRequestProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PREMIUM')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: plans.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('Erreur : $e',
                    style: const TextStyle(color: AppColors.textSecondary))),
            data: (data) {
              final premium = data['premium'] as Map<String, dynamic>;
              final payment = data['payment'] as Map<String, dynamic>?;
              final features = (premium['features'] as List)
                  .map((e) => e.toString())
                  .toList();
              final price = premium['priceTnd'];
              final isPremium =
                  status.valueOrNull?['isPremium'] == true;
              final pending =
                  myReq.valueOrNull?['status'] == 'PENDING';

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  const Center(
                      child: Icon(Icons.workspace_premium,
                          color: AppColors.gold, size: 56)),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(isPremium ? 'Tu es Premium ⭐' : 'Deviens Premium',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 20),
                  GtCard(
                    border: Border.all(color: AppColors.gold, width: 1.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...features.map((f) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              child: Row(children: [
                                const Icon(Icons.check_circle,
                                    color: AppColors.gold, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(f,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary))),
                              ]),
                            )),
                        const Divider(height: 28),
                        Center(
                          child: Text('$price TND / mois',
                              style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isPremium)
                    const _InfoBox(
                      icon: Icons.verified,
                      color: AppColors.green,
                      text: 'Ton compte est Premium. Merci ! ⭐',
                    )
                  else if (pending)
                    const _InfoBox(
                      icon: Icons.hourglass_top,
                      color: AppColors.gold,
                      text:
                          'Paiement reçu — en attente de validation. Ton Premium '
                          'sera activé dès vérification. 🙏',
                    )
                  else if (payment != null)
                    _D17Payment(payment: payment)
                  else
                    const SizedBox.shrink(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _D17Payment extends ConsumerStatefulWidget {
  final Map<String, dynamic> payment;
  const _D17Payment({required this.payment});

  @override
  ConsumerState<_D17Payment> createState() => _D17PaymentState();
}

class _D17PaymentState extends ConsumerState<_D17Payment> {
  final _ref = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ref.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_ref.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Saisis la référence de ton virement D17.')));
      return;
    }
    setState(() => _sending = true);
    try {
      await ref
          .read(apiClientProvider)
          .post('/premium/request', body: {'reference': _ref.text.trim()});
      ref.invalidate(myPremiumRequestProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Preuve envoyée ! En attente de validation. 🙏')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final number = widget.payment['number']?.toString() ?? '';
    final price = widget.payment['priceTnd'];
    return GtCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.account_balance_wallet, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Payer par D17',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Text('1. Envoie $price TND via D17 au numéro :',
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: number));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Numéro copié ✅')));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                children: [
                  Text(number,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                  const Spacer(),
                  const Icon(Icons.copy, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('2. Saisis la référence du virement (ou "payé") :',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          GtTextField(
            controller: _ref,
            label: 'Référence D17',
            hint: 'ex: 123456 ou "payé le 16/08"',
          ),
          const SizedBox(height: 16),
          GtButton(
            label: 'J\'AI PAYÉ — ENVOYER LA PREUVE',
            icon: Icons.send,
            gradient: AppColors.goldGradient,
            loading: _sending,
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ton Premium sera activé après vérification du paiement.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoBox(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return GtCard(
      color: color.withValues(alpha: 0.12),
      border: Border.all(color: color.withValues(alpha: 0.5)),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
