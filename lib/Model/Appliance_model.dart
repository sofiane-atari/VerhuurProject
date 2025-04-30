class ApplianceModel {
  final String id;
  final String naam;
  final String afbeelding;
  final double prijs;
  final String eenheid;
  final bool isBeschikbaar;
  final String locatie;
  final List<String> genre;
  final String staat;

  ApplianceModel({
    required this.id,
    required this.naam,
    required this.afbeelding,
    required this.prijs,
    required this.eenheid,
    required this.isBeschikbaar,
    required this.locatie,
    required this.genre,
    required this.staat,
  });
}
