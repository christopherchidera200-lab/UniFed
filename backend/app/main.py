"""CloudIntel API.

The same ASGI app serves uvicorn locally and Lambda in AWS (via Mangum in handler.py),
so there is exactly one code path to reason about.
"""
from __future__ import annotations

import asyncio
from collections.abc import AsyncIterator

from fastapi import Depends, FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, StreamingResponse

from app.auth import Principal, get_principal
from app.collectors import registry
from app.config import get_settings
from app.errors import CloudIntelError, NotFound
from app.logging_config import configure_logging, get_logger
from app.orchestrator import run_investigation, stream_investigation
from app.schemas import (
    CollectorResult,
    HealthResponse,
    InvestigationRequest,
    InvestigationResponse,
    InvestigationSummary,
)
from app.sse import SSE_HEADERS, format_sse
from app.storage.repository import get_repository

VERSION = "0.1.0"

configure_logging()
log = get_logger(__name__)
settings = get_settings()

app = FastAPI(
    title="CloudIntel API",
    version=VERSION,
    description=(
        "Legal OSINT aggregation. Public sources and authorized APIs only — "
        "see docs/LEGAL_AND_ETHICS.md."
    ),
    docs_url="/docs",
    openapi_url="/openapi.json",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"] if settings.is_local else [],
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)


@app.exception_handler(CloudIntelError)
async def cloudintel_error_handler(_: Request, exc: CloudIntelError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code, content={"error": exc.code, "message": exc.message}
    )


@app.get("/health", response_model=HealthResponse, tags=["system"])
async def health() -> HealthResponse:
    return HealthResponse(
        status="ok",
        environment=settings.environment,
        version=VERSION,
        collectors=registry.names(),
    )


@app.get("/collectors", tags=["system"])
async def list_collectors() -> list[dict]:
    """Expose the source catalogue, including the legal basis for each source."""
    return [
        {
            "name": c.name,
            "description": c.description,
            "supported_types": [t.value for t in c.supported_types],
            "legal_basis": c.legal_basis,
            "requires_api_key": c.requires_api_key,
        }
        for c in (registry.get(n) for n in registry.names())
        if c
    ]


@app.post("/investigations", response_model=InvestigationResponse, tags=["investigations"])
async def create_investigation(
    request: InvestigationRequest, principal: Principal = Depends(get_principal)
) -> InvestigationResponse:
    result = await run_investigation(request)
    repository = get_repository()
    await repository.save_investigation(result, principal.sub, principal.tier)
    await repository.record_audit(
        principal.sub,
        "investigation.create",
        {"target": result.target, "type": result.target_type.value},
    )
    return result


@app.post(
    "/investigations/stream",
    tags=["investigations"],
    response_class=StreamingResponse,
    responses={
        200: {
            "content": {"text/event-stream": {}},
            "description": (
                "Server-Sent Event stream. Emits `started`, then one `collector` event "
                "per source in completion order, then `complete` with the scored result. "
                "An `error` event is emitted if the investigation fails after the stream "
                "has already opened."
            ),
        }
    },
)
async def create_investigation_stream(
    request: InvestigationRequest, principal: Principal = Depends(get_principal)
) -> StreamingResponse:
    """Stream an investigation, emitting each collector's result as it settles.

    Rationale: total latency is set by the slowest third-party source, so a blocking
    response makes fast collectors wait for slow ones. Streaming lets the UI paint
    DNS/TLS/HTTP in seconds while a slow source resolves in its own time.

    Validation runs BEFORE the response starts so a bad target still returns a real
    4xx. Once the stream is open the status line is already sent, so later failures
    can only be reported in-band as an `error` event.
    """
    stream = stream_investigation(request)

    # Pull the first event eagerly. _prepare() runs here, so InvalidTarget and
    # ForbiddenTarget propagate to the exception handler and produce a proper
    # 400/403 instead of a 200 stream whose first frame is an error.
    try:
        first_event, first_payload = await anext(stream)
    except StopAsyncIteration:  # pragma: no cover - generator always yields 'started'
        raise CloudIntelError("Investigation produced no events") from None

    async def event_source() -> AsyncIterator[str]:
        repository = get_repository()
        yield format_sse(first_event, first_payload)

        try:
            async for event, payload in stream:
                if isinstance(payload, InvestigationResponse):
                    await repository.save_investigation(
                        payload, principal.sub, principal.tier
                    )
                    await repository.record_audit(
                        principal.sub,
                        "investigation.create",
                        {"target": payload.target, "type": payload.target_type.value},
                    )
                    yield format_sse(event, payload.model_dump(mode="json"))
                elif isinstance(payload, CollectorResult):
                    yield format_sse(event, payload.model_dump(mode="json"))
                else:
                    yield format_sse(event, payload)
        except asyncio.CancelledError:
            # Client disconnected. Let the generator's finally block cancel the
            # in-flight collectors; do not emit anything to a closed socket.
            raise
        except CloudIntelError as exc:
            log.warning("investigation.stream_error", code=exc.code, error=exc.message)
            yield format_sse("error", {"error": exc.code, "message": exc.message})
        except Exception as exc:  # noqa: BLE001 - stream must not die silently
            log.exception("investigation.stream_failed", error=str(exc))
            yield format_sse(
                "error",
                {"error": "internal_error", "message": "The investigation failed unexpectedly."},
            )

    return StreamingResponse(
        event_source(), media_type="text/event-stream", headers=SSE_HEADERS
    )


@app.get(
    "/investigations", response_model=list[InvestigationSummary], tags=["investigations"]
)
async def list_investigations(
    limit: int = 25, principal: Principal = Depends(get_principal)
) -> list[InvestigationSummary]:
    return await get_repository().list_investigations(principal.sub, min(limit, 100))


@app.get(
    "/investigations/{investigation_id}",
    response_model=InvestigationResponse,
    tags=["investigations"],
)
async def get_investigation(
    investigation_id: str, principal: Principal = Depends(get_principal)
) -> InvestigationResponse:
    item = await get_repository().get_investigation(investigation_id)
    if item is None:
        raise NotFound(f"Investigation '{investigation_id}' not found")
    if item["user_sub"] != principal.sub and not principal.is_admin:
        # Do not leak existence to a non-owner.
        raise NotFound(f"Investigation '{investigation_id}' not found")
    return InvestigationResponse.model_validate(item["payload"])
