import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { MiniGameResultDto } from './dto/result.dto';

/** Décode les entités HTML renvoyées par l'API de quiz. */
function decodeEntities(input: string): string {
  const map: Record<string, string> = {
    '&quot;': '"',
    '&#039;': "'",
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&eacute;': 'é',
    '&egrave;': 'è',
    '&agrave;': 'à',
    '&ldquo;': '"',
    '&rdquo;': '"',
    '&hellip;': '…',
    '&shy;': '',
  };
  return input.replace(
    /&[a-zA-Z0-9#]+;/g,
    (m) => map[m] ?? m,
  );
}

@Injectable()
export class MinigamesService {
  constructor(private readonly prisma: PrismaService) {}

  /** Catalogue des mini-jeux V1 (spec §12). */
  catalog() {
    return [
      { slug: 'tic-tac-toe', name: 'Tic-Tac-Toe', description: 'Joue avec tes amis' },
      { slug: 'connect-four', name: 'Puissance 4', description: 'Défie un joueur' },
      { slug: 'quiz', name: 'Quiz Game', description: 'Teste tes connaissances' },
      { slug: 'rock-paper-scissors', name: 'Pierre-Papier-Ciseaux', description: 'Le classique' },
      { slug: 'reaction', name: 'Reaction Time', description: 'Teste tes réflexes' },
    ];
  }

  /**
   * Récupère des questions de quiz depuis une source en ligne (Open Trivia DB).
   * category: 15 = Jeux vidéo, 9 = Culture générale, etc.
   */
  async fetchQuiz(category: number, amount: number) {
    const url = `https://opentdb.com/api.php?amount=${amount}&category=${category}&type=multiple`;
    const res = await fetch(url);
    if (!res.ok) return [];
    const data = (await res.json()) as {
      results?: {
        question: string;
        correct_answer: string;
        incorrect_answers: string[];
      }[];
    };
    return (data.results ?? []).map((q) => {
      const options = [...q.incorrect_answers, q.correct_answer];
      for (let i = options.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [options[i], options[j]] = [options[j], options[i]];
      }
      const answer = options.indexOf(q.correct_answer);
      return {
        question: decodeEntities(q.question),
        options: options.map(decodeEntities),
        answer,
      };
    });
  }

  /**
   * Enregistre le résultat d'une partie et met à jour les statistiques.
   * (Le déroulé du jeu est côté client ; ici on ne stocke que le résultat.)
   */
  async recordResult(userId: string, dto: MiniGameResultDto) {
    await this.prisma.statistics.update({
      where: { userId },
      data: {
        matchesPlayed: { increment: 1 },
        wins: { increment: dto.won ? 1 : 0 },
      },
    });
    return { recorded: true };
  }
}
