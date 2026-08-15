/**
 * Logique pure des mini-jeux multijoueurs (Tic-Tac-Toe, Puissance 4).
 * Joueur 1 = valeur 1, Joueur 2 = valeur 2, case vide = 0.
 */

export type GameType = 'tic-tac-toe' | 'connect-four' | 'rock-paper-scissors';

export interface GameState {
  game: GameType;
  board: number[]; // TTT: 9 | C4: 42 | RPS: [c1,c2,s1,s2,last1,last2]
  turn: 1 | 2;
  winner: 0 | 1 | 2 | 3; // 0 = en cours, 1/2 = gagnant, 3 = nul
}

export function createBoard(game: GameType): number[] {
  if (game === 'tic-tac-toe') return Array(9).fill(0);
  if (game === 'connect-four') return Array(42).fill(0);
  // RPS : choix p1, choix p2, score p1, score p2, dernier choix p1, p2.
  return [-1, -1, 0, 0, -1, -1];
}

/**
 * Applique un coup. Renvoie true si le coup est valide.
 * Pour C4, `index` est la COLONNE (0..6) ; le jeton tombe en bas.
 */
export function applyMove(
  state: GameState,
  player: 1 | 2,
  index: number,
): boolean {
  if (state.winner !== 0) return false;

  // Pierre-Papier-Ciseaux : simultané (pas de tour).
  if (state.game === 'rock-paper-scissors') {
    if (index < 0 || index > 2) return false;
    const slot = player === 1 ? 0 : 1;
    if (state.board[slot] !== -1) return false; // déjà choisi ce round
    state.board[slot] = index;
    const c1 = state.board[0];
    const c2 = state.board[1];
    if (c1 !== -1 && c2 !== -1) {
      // Résolution du round.
      if (c1 !== c2) {
        const p1Wins =
          (c1 === 0 && c2 === 2) ||
          (c1 === 1 && c2 === 0) ||
          (c1 === 2 && c2 === 1);
        if (p1Wins) {
          state.board[2] += 1;
        } else {
          state.board[3] += 1;
        }
      }
      state.board[4] = c1; // mémorise pour l'affichage
      state.board[5] = c2;
      state.board[0] = -1;
      state.board[1] = -1;
      if (state.board[2] >= 5) state.winner = 1;
      else if (state.board[3] >= 5) state.winner = 2;
    }
    return true;
  }

  if (state.turn !== player) return false;

  if (state.game === 'tic-tac-toe') {
    if (index < 0 || index > 8 || state.board[index] !== 0) return false;
    state.board[index] = player;
  } else {
    // Puissance 4 : trouve la case la plus basse de la colonne.
    const col = index;
    if (col < 0 || col > 6) return false;
    let placed = -1;
    for (let row = 5; row >= 0; row--) {
      const cell = row * 7 + col;
      if (state.board[cell] === 0) {
        state.board[cell] = player;
        placed = cell;
        break;
      }
    }
    if (placed === -1) return false; // colonne pleine
  }

  state.winner = computeWinner(state);
  if (state.winner === 0) {
    state.turn = player === 1 ? 2 : 1;
  }
  return true;
}

export function computeWinner(state: GameState): 0 | 1 | 2 | 3 {
  const b = state.board;
  if (state.game === 'tic-tac-toe') {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    for (const [a, c, d] of lines) {
      if (b[a] !== 0 && b[a] === b[c] && b[a] === b[d]) return b[a] as 1 | 2;
    }
    return b.every((v) => v !== 0) ? 3 : 0;
  }

  // Puissance 4 (7×6)
  const at = (r: number, c: number) => b[r * 7 + c];
  for (let r = 0; r < 6; r++) {
    for (let c = 0; c < 7; c++) {
      const p = at(r, c);
      if (p === 0) continue;
      if (c + 3 < 7 && p === at(r, c + 1) && p === at(r, c + 2) && p === at(r, c + 3)) return p as 1 | 2;
      if (r + 3 < 6 && p === at(r + 1, c) && p === at(r + 2, c) && p === at(r + 3, c)) return p as 1 | 2;
      if (r + 3 < 6 && c + 3 < 7 && p === at(r + 1, c + 1) && p === at(r + 2, c + 2) && p === at(r + 3, c + 3)) return p as 1 | 2;
      if (r + 3 < 6 && c - 3 >= 0 && p === at(r + 1, c - 1) && p === at(r + 2, c - 2) && p === at(r + 3, c - 3)) return p as 1 | 2;
    }
  }
  return b.every((v) => v !== 0) ? 3 : 0;
}
