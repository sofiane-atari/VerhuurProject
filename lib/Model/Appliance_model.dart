import 'package:cloud_firestore/cloud_firestore.dart';

class ApplianceModel {
  final String id;
  final String naam;
  final String afbeelding;
  final double prijs;
  final String eenheid;
  bool isBeschikbaar;
  final GeoPoint? locatie;
  final List<String> genre;
  final String staat;
  final String eigenaarId;
  DateTime? reservedUntil;
  String? huurderId;

  ApplianceModel({
    required this.id,
    required this.naam,
    required this.afbeelding,
    required this.prijs,
    required this.eenheid,
    required this.isBeschikbaar,
    this.locatie,
    required this.genre,
    required this.staat,
    required this.eigenaarId,
    this.reservedUntil,
    this.huurderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'Naam': naam,
      'afbeelding': afbeelding,
      'prijs': prijs,
      'eenheid': eenheid,
      'isBeschikbaar': isBeschikbaar,
      'locatie': locatie,
      'genre': genre,
      'staat': staat,
      'eigenaarId': eigenaarId,
      'reservedUntil':
          reservedUntil != null ? Timestamp.fromDate(reservedUntil!) : null,
      'huurderId': huurderId,
    };
  }
}
