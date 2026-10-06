#!/usr/bin/env python3
"""Genera data/handmade.txt: tutorial, stanze delle abilità e arene dei boss.

I livelli fatti a mano sono descritti qui con poche primitive (pavimento, muri,
oggetti) invece che carattere per carattere: è più facile non sbagliare i conti
su griglie larghe 240 colonne. La legenda dei caratteri è in src/gen/ChunkLib.gd.

Uso:  python3 tools/make_handmade.py
"""
import os

ROWS = 17


class Grid:
    def __init__(self, w, h=ROWS, ground=11):
        self.w, self.h = w, h
        self.g = [["."] * w for _ in range(h)]
        self.ground = ground
        if ground is not None:
            self.fill(0, ground, w - 1, h - 1)

    def put(self, x, y, ch):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.g[y][x] = ch

    def fill(self, x0, y0, x1, y1, ch="#"):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.put(x, y, ch)

    def row(self, x0, x1, y, ch):
        self.fill(x0, y, x1, y, ch)

    def pit(self, x0, x1, depth=None):
        """Buco nel pavimento (fino in fondo, o profondo `depth` tile)."""
        bottom = self.h - 1 if depth is None else self.ground + depth - 1
        self.fill(x0, self.ground, x1, bottom, ".")

    def text(self):
        return "\n".join("".join(r) for r in self.g)


def tutorial():
    g = Grid(240, ground=12)
    top = 11  # riga su cui si cammina
    # 1. risveglio
    g.put(3, top, "P")
    g.put(3, 2, "1")
    # 2. primo salto: un cuscino basso
    g.put(27, 2, "2")
    g.fill(34, top, 35, top)
    # 3. salto alto: una pila di libri
    g.put(50, 2, "3")
    g.fill(58, top - 2, 60, top)
    # 4. frammenti di sogno sopra un piccolo buco
    g.put(74, 2, "4")
    g.pit(82, 83)
    for x, y in [(80, 10), (81, 9), (82, 8), (83, 8), (84, 9), (85, 10)]:
        g.put(x, y, "o")
    for x in range(64, 72, 2):
        g.put(x, top, "o")
    # 5. primo checkpoint: il carillon
    g.put(97, 2, "5")
    g.put(101, top, "K")
    # 6. primo nemico: un soldatino in uno spazio largo
    g.put(110, 2, "6")
    g.fill(115, top, 115, top)
    g.fill(133, top, 133, top)
    g.put(126, top, "a")
    # 7. il vuoto: prima una rete di lana, poi un buco vero ma facile
    g.put(138, 2, "7")
    g.pit(144, 147, depth=2)
    g.row(144, 147, 14, "M")
    for x in range(144, 148):
        g.put(x, 9, "o")
    g.pit(158, 159)
    g.put(164, top, "K")
    # 8. primo segreto: un muro con la crepa nasconde una stanzetta
    g.fill(178, top, 179, top)
    g.fill(180, top - 1, 181, top)
    g.fill(182, top - 2, 190, top)
    g.fill(185, top - 1, 189, top, ".")
    g.fill(190, top - 1, 190, top, "C")
    g.put(186, top - 1, "S")
    g.put(192, 2, "8")
    for x in range(183, 190, 2):
        g.put(x, top - 3, "o")
    # 9. mini prova: salto alto, nemico e buco, senza suggerimenti
    g.fill(204, top - 1, 205, top)
    g.fill(209, top, 209, top)
    g.fill(219, top, 219, top)
    g.put(214, top, "a")
    g.pit(223, 224)
    g.put(223, 9, "o")
    g.put(224, 9, "o")
    # 10. portale
    g.put(229, 2, "9")
    g.put(235, top, "X")
    hints = "tut_move,tut_jump,tut_high,tut_frag,tut_cp,tut_enemy,tut_pit,tut_secret,tut_end"
    return "tutorial", hints, g


def intro(world):
    """Stanza che presenta la nuova abilità: spazio sicuro, gesto, piccola prova."""
    top = 10
    if world == 2:  # doppio salto
        g = Grid(30)
        g.put(2, 2, "1")
        g.fill(12, 6, 14, top)  # muro di 5 tile
        g.put(16, 2, "2")
        g.pit(19, 24)  # vuoto di 6 tile
        for x in range(19, 25):
            g.put(x, 7, "o")
        hints = "ab_doppio,ab_doppio2"
    elif world == 3:  # scatto
        g = Grid(40)
        g.put(2, 2, "1")
        g.put(8, 2, "2")
        g.fill(12, 0, 17, top - 1)  # soglia bassa: si passa solo scivolando
        for x in range(12, 18):
            g.put(x, top, "o")
        g.pit(24, 30)  # vuoto di 7 tile: salto + scatto in aria
        hints = "ab_scatto,ab_scatto2"
    elif world == 4:  # bolla
        g = Grid(42)
        g.put(2, 2, "1")
        g.put(9, 2, "2")
        g.fill(14, 2, 16, top)  # muro di 9 tile
        for y in range(3, 10, 2):
            g.put(12, y, "o")
        g.pit(22, 33)  # vuoto di 12 tile
        hints = "ab_bolla,ab_bolla2"
    elif world == 5:  # gravità
        g = Grid(40)
        g.put(2, 2, "1")
        g.fill(6, 0, 34, 3)  # soffitto
        g.put(9, 6, "2")
        g.row(12, 21, top, "^")
        for x in range(12, 22, 2):
            g.put(x, 5, "o")
        g.row(26, 30, 4, "v")
        hints = "ab_gravita,ab_gravita2"
    elif world == 6:  # rallentare il tempo
        g = Grid(40)
        g.put(2, 2, "1")
        g.put(8, 2, "2")
        g.put(13, top, "Z")
        g.put(19, top - 1, "Z")
        g.pit(24, 31)
        g.put(27, 11, "H")
        hints = "ab_tempo,ab_tempo2"
    elif world == 7:  # schianto
        g = Grid(40)
        g.put(2, 2, "1")
        g.fill(10, 11, 12, 12, "B")  # casse da rompere
        g.fill(10, 13, 22, 14, ".")  # galleria
        g.fill(14, 0, 17, top)  # muro in superficie
        g.fill(20, 11, 22, 12, ".")  # uscita della galleria
        g.row(20, 22, 15, "M")
        g.put(19, 2, "2")
        g.row(25, 26, 11, "M")
        g.fill(28, 3, 31, top)  # parete di 8 tile: serve il super rimbalzo
        for y in range(3, 10, 2):
            g.put(26, y, "o")
        hints = "ab_schianto,ab_schianto2"
    elif world == 8:  # riflesso
        g = Grid(34)
        g.put(2, 2, "1")
        g.put(6, 2, "2")
        g.put(10, top, "T")
        g.put(18, top, "T")
        g.fill(26, 0, 26, 6)
        g.fill(26, 7, 26, top, "D")
        hints = "ab_riflesso,ab_riflesso2"
    elif world == 9:  # planata
        g = Grid(46)
        g.put(2, 2, "1")
        g.pit(10, 19)  # vuoto di 10 tile: si plana
        g.put(23, 2, "2")
        g.fill(26, 3, 27, top, "~")  # corrente d'aria
        g.fill(30, 5, 33, top)  # cengia alta
        for x in range(34, 40):
            g.put(x, 6 + (x - 34) // 2, "o")
        hints = "ab_planata,ab_planata2"
    else:  # 10: selettore
        g = Grid(36)
        g.put(2, 2, "1")
        g.put(6, 2, "2")
        g.fill(9, 0, 13, top - 1)  # soglia bassa: scatto
        g.fill(21, 2, 23, top)  # muro alto: bolla
        hints = "ab_selettore,ab_selettore2"
    return "intro_%d" % world, hints, g


def boss(world):
    """Arene dei boss: una schermata (alta due per l'Occhio del Ciclone)."""
    if world == 9:
        g = Grid(30, 34, ground=31)
        top = 30
        g.fill(4, 8, 5, top, "~")
        g.fill(14, 14, 15, top, "~")
        g.fill(24, 4, 25, top, "~")
        g.row(8, 11, 24, "=")
        g.row(18, 21, 20, "=")
        g.row(7, 10, 14, "=")
        g.row(18, 21, 9, "=")
        g.put(20, 8, "S")
        g.put(2, top, "P")
        g.put(15, top, "Q")
        g.put(27, top, "X")
        return "boss_9", "", g
    g = Grid(30, ground=14)
    top = 13
    g.put(3, top, "P")
    g.put(26, top, "X")
    if world == 1:
        g.row(5, 8, 11, "=")
        g.row(21, 24, 11, "=")
        g.put(22, 10, "S")
        g.put(20, top, "Q")
    elif world == 2:
        g.row(3, 6, 10, "=")
        g.row(23, 26, 10, "=")
        g.row(9, 12, 7, "=")
        g.row(17, 20, 7, "=")
        g.put(11, 6, "S")
        g.put(15, top, "Q")
    elif world == 3:
        g.put(24, top, "Q")
        g.row(2, 4, 10, "=")
        g.put(3, 9, "S")
    elif world == 4:
        g.put(15, top, "Q")
        g.row(14, 16, 4, "=")
        g.put(15, 3, "S")
    elif world == 5:
        g.fill(0, 0, 29, 2)
        g.put(18, top, "Q")
        g.put(15, 3, "S")
    elif world == 6:
        g.row(13, 16, 9, "=")
        g.row(3, 5, 10, "=")
        g.row(24, 26, 10, "=")
        g.put(4, 9, "S")
        g.put(15, top, "Q")
    elif world == 7:
        g.row(3, 5, 14, "M")
        g.row(24, 26, 14, "M")
        g.put(15, top, "Q")
        g.row(3, 5, 5, "=")
        g.put(4, 4, "S")
    elif world == 8:
        g.put(6, top, "T")
        g.put(23, top, "T")
        g.put(15, top, "Q")
        g.row(13, 16, 10, "=")
        g.put(15, 9, "S")
    elif world == 10:
        g.fill(0, 0, 29, 1)
        g.put(6, top, "T")
        g.put(23, top, "T")
        g.row(10, 11, 14, "M")
        g.row(18, 19, 14, "M")
        g.put(15, top, "Q")
        g.row(1, 3, 7, "=")
        g.put(2, 6, "S")
    return "boss_%d" % world, "", g


def main():
    out = [
        "; File generato da tools/make_handmade.py: non modificare a mano.",
        "; Tutorial (Mondo 1, livello 1), stanze delle abilità (livello 1 dei mondi 2-10) e arene dei boss.",
        "",
    ]
    levels = [tutorial()] + [intro(w) for w in range(2, 11)] + [boss(w) for w in range(1, 11)]
    for name, hints, g in levels:
        head = "@ %s" % name
        if hints:
            head += " hints=%s" % hints
        out.append(head)
        out.append(g.text())
        out.append("")
    path = os.path.join(os.path.dirname(__file__), "..", "data", "handmade.txt")
    with open(path, "w") as f:
        f.write("\n".join(out))
    print("scritto", os.path.normpath(path), "-", len(levels), "livelli")


if __name__ == "__main__":
    main()
