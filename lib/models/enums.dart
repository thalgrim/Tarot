enum Contract {
  petite('Prise', 1),
  garde('Garde', 2),
  gardeSans('Garde sans le chien', 4),
  gardeContre('Garde contre le chien', 6);

  final String label;
  final int multiplier;

  const Contract(this.label, this.multiplier);
}

enum Camp {
  attaque('Attaque'),
  defense('Defense');

  final String label;

  const Camp(this.label);
}

enum PetitAuBout {
  personne('Non', null),
  attaque('Attaque', Camp.attaque),
  defense('Defense', Camp.defense);

  final String label;
  final Camp? camp;

  const PetitAuBout(this.label, this.camp);

  double get bonus {
    if (camp == Camp.attaque) return 10;
    if (camp == Camp.defense) return -10;
    return 0;
  }
}

enum Poignee {
  aucune('Aucune', 0),
  simple('Simple', 20),
  doublePoignee('Double', 30),
  triplePoignee('Triple', 40);

  final String label;
  final int bonus;

  const Poignee(this.label, this.bonus);
}

enum Chelem {
  aucun('Non', 0),
  annonceReussi('Annonce, reussi', 400),
  nonAnnonceReussi('Reussi sans annonce', 200),
  annonceEchoue('Annonce, chute', -200);

  final String label;
  final int bonus;

  const Chelem(this.label, this.bonus);
}
