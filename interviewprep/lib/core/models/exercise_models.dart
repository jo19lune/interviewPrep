import 'package:json_annotation/json_annotation.dart';

part 'exercise_models.g.dart';

@JsonSerializable()
class ExerciceCreateRequest {
    final String titre;
    final String description;
    final String domaine;
    final String difficulte;
    @JsonKey(name: 'duree_sec')
    final int dureeSec;
    final List<dynamic>? questions; // Or List<Map<String, dynamic>>
    final List<String>? etiquettes;

    ExerciceCreateRequest({
        required this.titre,
        required this.description,
        required this.domaine,
        required this.difficulte,
        required this.dureeSec,
        this.questions,
        this.etiquettes,
    });

    factory ExerciceCreateRequest.fromJson(Map<String, dynamic> json) => _$ExerciceCreateRequestFromJson(json);
    Map<String, dynamic> toJson() => _$ExerciceCreateRequestToJson(this);
}

@JsonSerializable()
class ExerciceResponse {
    final String id;
    final String titre;
    final String description;
    final String domaine;
    final String difficulte;
    @JsonKey(name: 'duree_sec')
    final int dureeSec;
    final List<dynamic>? questions;
    final List<String>? etiquettes;
    @JsonKey(name: 'cree_le')
    final DateTime? creeLe;

    ExerciceResponse({
        required this.id,
        required this.titre,
        required this.description,
        required this.domaine,
        required this.difficulte,
        required this.dureeSec,
        this.questions,
        this.etiquettes,
        this.creeLe,
    });

    factory ExerciceResponse.fromJson(Map<String, dynamic> json) => _$ExerciceResponseFromJson(json);
    Map<String, dynamic> toJson() => _$ExerciceResponseToJson(this);
}
