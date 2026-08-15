import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_button.dart';
import '../../core/widgets/gt_scaffold.dart';

class _Question {
  final String question;
  final List<String> options;
  final int answer;
  final String image; // grande "image" emoji illustrant la question
  const _Question(this.question, this.options, this.answer, {this.image = '🎮'});
}

class _Category {
  final String name;
  final IconData icon;
  final Gradient gradient;
  final List<_Question> questions;
  const _Category(this.name, this.icon, this.gradient, this.questions);
}

/// Quiz Game (spec §12) — TOUT en tunisien (derja) : Tunisie / Gaming / Voitures.
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = _buildCategories();
    return Scaffold(
      appBar: AppBar(title: const Text('QUIZ')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const Text('اختار قسم',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('جاوب على أكثر ما تنجم من أسئلة !',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              ...categories.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GtCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => _QuizPlay(category: c)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: c.gradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(c.icon, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                                Text('${c.questions.length} أسئلة',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  List<_Category> _buildCategories() {
    const tn = LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFB91C1C)]);
    const gaming =
        LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]);
    const cars = LinearGradient(colors: [Color(0xFF22D3EE), Color(0xFF0EA5E9)]);

    return [
      _Category('تونس 🇹🇳', Icons.flag, tn, const [
        _Question('شنوة عاصمة تونس ؟',
            ['صفاقس', 'تونس', 'سوسة', 'بنزرت'], 1),
        _Question('شنوة الفلوس اللي نستعملوها في تونس ؟',
            ['الدرهم', 'الدينار', 'اليورو', 'الريال'], 1),
        _Question('الماكلة التونسية الأصيلة هي ؟',
            ['السوشي', 'الكسكسي', 'البيتزا', 'التاكوس'], 1),
        _Question('أنهي بحر يلمس تونس ؟',
            ['البحر الأحمر', 'المحيط الأطلسي', 'البحر الأبيض المتوسط', 'البحر الأسود'],
            2),
        _Question('الموقع الأثري القديم الحذا تونس ؟',
            ['قرطاج', 'البتراء', 'الأقصر', 'بابل'], 0),
        _Question('أنهي صحراء في الجنوب التونسي ؟',
            ['كالاهاري', 'الصحراء الكبرى', 'قوبي', 'أتاكاما'], 1),
        _Question('مدينة تونسية مشهورة بالواحات ؟',
            ['توزر', 'أريانة', 'بن عروس', 'قابس'], 0),
        _Question('تونس خذات استقلالها في ؟',
            ['1945', '1956', '1962', '1975'], 1),
        _Question('فيلم Star Wars تصوّر في أنهي مدينة تونسية ؟',
            ['تطاوين', 'نابل', 'القيروان', 'قفصة'], 0),
        _Question('أنهي رياضة الأكثر شعبية في تونس ؟',
            ['الرقبي', 'كرة القدم', 'الكريكت', 'الهوكي'], 1),
        _Question('"برشا" في الدارجة معناها ؟',
            ['شوية', 'ياسر / كثير', 'وقتاش', 'وين'], 1),
        _Question('"باهي" معناها ؟',
            ['موش مليح', 'مليح / حسنا', 'كبير', 'صغير'], 1),
      ]),
      _Category('قيمينغ 🎮', Icons.sports_esports, gaming, const [
        _Question('شكون صنع لعبة Valorant ؟',
            ['Valve', 'Riot Games', 'Epic Games', 'Blizzard'], 1, image: '🎯'),
        _Question('قداش لاعب في الفريق المصنّف متاع Valorant ؟',
            ['4', '5', '6', '3'], 1, image: '👥'),
        _Question('أنهي لعبة تبني فيها بالبلوكات ؟',
            ['FIFA', 'Minecraft', 'Rocket League', 'Dota 2'], 1, image: '🧱'),
        _Question('"Battle Royale" معناها ؟',
            ['واحد ضد واحد', 'آخر لاعب يبقى حي', 'سباق', 'أحاجي'], 1, image: '🪂'),
        _Question('Rocket League تخلط الكرة مع شنوة ؟',
            ['الطيارات', 'الكراهب', 'الموتورات', 'الفلايك'], 1, image: '🚗'),
        _Question('"GG" في الڤيمينغ معناها ؟',
            ['Good Game', 'Go Go', 'Great Gun', 'Game Group'], 0, image: '🤝'),
        _Question('شكون الماسكوت متاع Nintendo ؟',
            ['Sonic', 'Mario', 'Kratos', 'Master Chief'], 1, image: '🍄'),
        _Question('CS2 نوعها شنوة ؟',
            ['MOBA', 'FPS', 'MMORPG', 'سباق'], 1, image: '🔫'),
        _Question('Fortnite شكون صنعها ؟',
            ['Ubisoft', 'Epic Games', 'EA', 'Activision'], 1, image: '🏝️'),
        _Question('Free Fire نوعها شنوة ؟',
            ['MOBA', 'FPS', 'Battle Royale', 'سباق'], 2, image: '🔥'),
        _Question('"FPS" معناها ؟',
            ['First Person Shooter', 'Fast Play Style', 'Final Play Score',
                'Free Player Server'],
            0, image: '🎯'),
        _Question('أنهي لعبة فيها العميل "Jett" ؟',
            ['Fortnite', 'Valorant', 'Apex', 'CS2'], 1, image: '💨'),
        _Question('شكون بطل لعبة God of War ؟',
            ['Kratos', 'Master Chief', 'Link', 'Nathan Drake'], 0, image: '🪓'),
        _Question('لعبة PUBG نوعها ؟',
            ['سباق', 'Battle Royale', 'MOBA', 'أحاجي'], 1, image: '🪖'),
        _Question('"NPC" معناها في الألعاب ؟',
            ['لاعب حقيقي', 'شخصية يسيّرها الجهاز', 'سلاح', 'خريطة'], 1, image: '🤖'),
        _Question('أنهي شركة صنعات PlayStation ؟',
            ['Microsoft', 'Sony', 'Nintendo', 'Sega'], 1, image: '🎮'),
        _Question('Xbox تابعة لأنهي شركة ؟',
            ['Sony', 'Microsoft', 'Apple', 'Google'], 1, image: '🟢'),
        _Question('لعبة League of Legends نوعها ؟',
            ['FPS', 'MOBA', 'سباق', 'رياضة'], 1, image: '⚔️'),
        _Question('"Noob" معناها ؟',
            ['لاعب محترف', 'لاعب مبتدئ', 'مدرّب', 'حكم'], 1, image: '🐣'),
        _Question('في FIFA/FC، "clean sheet" يعني ؟',
            ['ما دخلتش أهداف', 'ربح بلا لعب', 'كارتون أحمر', 'ركلة جزاء'], 0,
            image: '🥅'),
        _Question('أنهي لعبة مشهورة بالـ "Fatality" ؟',
            ['Tekken', 'Mortal Kombat', 'Street Fighter', 'FIFA'], 1, image: '🥊'),
        _Question('"Lag" في اللعب معناه ؟',
            ['تأخير/بطء الكونيكسيون', 'ربح', 'مستوى جديد', 'سلاح'], 0, image: '📶'),
        _Question('GTA شكون صنعها ؟',
            ['Rockstar Games', 'EA', 'Ubisoft', 'Capcom'], 0, image: '🚓'),
        _Question('أنهي جهاز محمول متاع Nintendo ؟',
            ['Switch', 'PS5', 'Xbox Series', 'Steam Deck'], 0, image: '🕹️'),
      ]),
      _Category('كراهب 🚗', Icons.directions_car, cars, const [
        _Question('أنهي ماركة اللوغو متاعها حصان ؟',
            ['Lamborghini', 'Ferrari', 'Porsche', 'Bugatti'], 1),
        _Question('Mercedes من أنهي بلاد ؟',
            ['فرنسا', 'إيطاليا', 'ألمانيا', 'اليابان'], 2),
        _Question('"Veyron" من أنهي ماركة ؟',
            ['Bugatti', 'McLaren', 'Audi', 'BMW'], 0),
        _Question('أنهي ماركة فيها 4 حلقات في اللوغو ؟',
            ['Audi', 'Toyota', 'Opel', 'Renault'], 0),
        _Question('Tesla تصنع كراهب من نوع ؟',
            ['ديزل', 'كهربائية', 'بنزين', 'هيدروجين'], 1),
        _Question('اللوغو متاع الثور يرمز لأنهي ماركة ؟',
            ['Lamborghini', 'Ferrari', 'Ford', 'Dodge'], 0),
        _Question('"Supra" من أنهي ماركة يابانية ؟',
            ['Honda', 'Toyota', 'Nissan', 'Mazda'], 1),
        _Question('Formule 1 نوع سباق ؟',
            ['راليي', 'سباق حلبة', 'دريفت', 'off-road'], 1),
        _Question('Rolls-Royce ماركة فخمة من أنهي بلاد ؟',
            ['أمريكا', 'بريطانيا', 'ألمانيا', 'إيطاليا'], 1),
        _Question('BMW من أنهي بلاد ؟',
            ['فرنسا', 'ألمانيا', 'إيطاليا', 'اليابان'], 1),
        _Question('"Golf" موديل مشهور متاع أنهي ماركة ؟',
            ['Peugeot', 'Volkswagen', 'Renault', 'Fiat'], 1),
        _Question('الكابوس (الكوتشوك) في الكرهبة يعني ؟',
            ['المنبّه', 'العجلة/الپنو', 'الزجاج', 'الموتور'], 1),
      ]),
    ];
  }
}

class _QuizPlay extends StatefulWidget {
  final _Category category;
  const _QuizPlay({required this.category});

  @override
  State<_QuizPlay> createState() => _QuizPlayState();
}

class _QuizPlayState extends State<_QuizPlay> {
  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;

  List<_Question> get _questions => widget.category.questions;

  void _choose(int i) {
    if (_answered) return;
    setState(() {
      _selected = i;
      _answered = true;
      if (i == _questions[_index].answer) _score++;
    });
  }

  void _next() {
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
    } else {
      setState(() => _index = _questions.length);
    }
  }

  void _restart() {
    setState(() {
      _index = 0;
      _score = 0;
      _selected = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final finished = _index >= _questions.length;
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: finished ? _buildResult() : _buildQuestion(),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Text('سؤال ${_index + 1}/${_questions.length}',
                style: const TextStyle(color: AppColors.textSecondary)),
            const Spacer(),
            Text('النتيجة : $_score',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_index + 1) / _questions.length,
            minHeight: 8,
            backgroundColor: AppColors.surfaceAlt,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 20),
        // "Image" de la question (grand emoji dans une carte).
        Center(
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Center(
                child: Text(q.image, style: const TextStyle(fontSize: 60))),
          ),
        ),
        const SizedBox(height: 20),
        Text(q.question,
            textAlign: TextAlign.right,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w700,
                height: 1.4)),
        const SizedBox(height: 20),
        ...List.generate(q.options.length, (i) {
          Color bg = AppColors.card;
          Color border = AppColors.stroke;
          if (_answered) {
            if (i == q.answer) {
              bg = AppColors.green.withValues(alpha: 0.18);
              border = AppColors.green;
            } else if (i == _selected) {
              bg = AppColors.danger.withValues(alpha: 0.18);
              border = AppColors.danger;
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _choose(i),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Text(q.options[i],
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          );
        }),
            ],
          ),
        ),
        if (_answered) ...[
          const SizedBox(height: 8),
          GtButton(
            label: _index < _questions.length - 1 ? 'السؤال اللي بعدو' : 'النتيجة',
            onPressed: _next,
          ),
        ],
      ],
    );
  }

  Widget _buildResult() {
    final pct = (_score / _questions.length * 100).round();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(pct >= 60 ? Icons.emoji_events : Icons.psychology,
              color: pct >= 60 ? AppColors.gold : AppColors.primary, size: 72),
          const SizedBox(height: 20),
          Text('$_score / ${_questions.length}',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 40,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            pct >= 80
                ? 'بطل ! 🏆'
                : pct >= 60
                    ? 'برافو ! 👍'
                    : 'زيد تمرّن شوية 💪',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          SizedBox(
              width: double.infinity,
              child: GtButton(label: 'عاود العب', onPressed: _restart)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GtOutlineButton(
              label: 'قسم آخر',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
