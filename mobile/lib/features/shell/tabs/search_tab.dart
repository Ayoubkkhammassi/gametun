import 'package:flutter/material.dart';
import '../../match/game_match_screen.dart';

/// Onglet Recherche → Game Match (spec §6-7), branché sur l'API réelle.
class SearchTab extends StatelessWidget {
  const SearchTab({super.key});

  @override
  Widget build(BuildContext context) => const GameMatchScreen();
}
