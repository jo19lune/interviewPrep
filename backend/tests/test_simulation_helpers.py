from app.services.simulation_helpers import normalize_feedback, score_answer


def test_score_answer_accepts_qcm_option_text():
    score, sentiment, _, analysis = score_answer(
        {
            "type": "qcm",
            "options": ["Python", "JavaScript"],
            "reponse_correcte": 0,
        },
        "Python",
    )

    assert score == 100.0
    assert sentiment == "Confident"
    assert analysis["pertinence"] == 100


def test_score_answer_rewards_structured_open_response():
    score, sentiment, tip, analysis = score_answer(
        {"type": "ouverte"},
        (
            "Dans cette situation, j'ai mené un projet avec mon équipe. "
            "J'ai défini une action et obtenu un résultat de 20% avec un KPI."
        ),
    )

    assert score >= 75
    assert sentiment == "Confident"
    assert "risques" in tip
    assert analysis["exemples"] == 85


def test_normalize_feedback_keeps_fallback_shape():
    feedback = normalize_feedback(
        {"score_global": 82, "recommandations": ["Pratiquer"]},
        fallback_score=70,
    )

    assert feedback["score_global"] == 82.0
    assert feedback["recommandations"] == ["Pratiquer"]
    assert feedback["points_forts"]
    assert feedback["ameliorations"]
