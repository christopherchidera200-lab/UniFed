def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert "dns" in body["collectors"]


def test_collector_catalogue_exposes_legal_basis(client):
    response = client.get("/collectors")
    assert response.status_code == 200
    for collector in response.json():
        assert collector["legal_basis"]


def test_rejects_private_ip_target(client):
    response = client.post(
        "/investigations", json={"target": "192.168.1.1", "target_type": "ip"}
    )
    assert response.status_code == 403
    assert response.json()["error"] == "forbidden_target"


def test_rejects_malformed_domain(client):
    response = client.post("/investigations", json={"target": "not-a-domain"})
    assert response.status_code == 400
    assert response.json()["error"] == "invalid_target"


def test_metadata_endpoint_ssrf_blocked(client):
    response = client.post(
        "/investigations", json={"target": "169.254.169.254", "target_type": "ip"}
    )
    assert response.status_code == 403


def test_unknown_investigation_returns_404(client):
    assert client.get("/investigations/does-not-exist").status_code == 404


def test_history_starts_empty(client):
    response = client.get("/investigations")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
