"""Cognito JWT verification.

Local development runs with CLOUDINTEL_AUTH_DISABLED=true and injects a dev principal, so the
API is usable without standing up a user pool. In any deployed environment the setting is false
and a valid RS256 token signed by the pool's JWKS is mandatory.
"""
from __future__ import annotations

import time
from dataclasses import dataclass

import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import jwt
from jose.exceptions import JWTError

from app.config import Settings, get_settings

_bearer = HTTPBearer(auto_error=False)
_jwks_cache: dict[str, tuple[float, dict]] = {}
_JWKS_TTL = 3600


@dataclass(frozen=True)
class Principal:
    sub: str
    email: str | None
    tier: str = "free"
    groups: tuple[str, ...] = ()

    @property
    def is_admin(self) -> bool:
        return "admin" in self.groups


DEV_PRINCIPAL = Principal(
    sub="dev-user", email="dev@localhost", tier="enterprise", groups=("admin",)
)


async def _get_jwks(settings: Settings) -> dict:
    url = (
        f"https://cognito-idp.{settings.aws_region}.amazonaws.com/"
        f"{settings.cognito_user_pool_id}/.well-known/jwks.json"
    )
    cached = _jwks_cache.get(url)
    if cached and time.time() - cached[0] < _JWKS_TTL:
        return cached[1]
    async with httpx.AsyncClient(timeout=5) as client:
        response = await client.get(url)
        response.raise_for_status()
        jwks = response.json()
    _jwks_cache[url] = (time.time(), jwks)
    return jwks


async def get_principal(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    settings: Settings = Depends(get_settings),
) -> Principal:
    if settings.auth_disabled:
        return DEV_PRINCIPAL

    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing bearer token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials
    try:
        jwks = await _get_jwks(settings)
        header = jwt.get_unverified_header(token)
        key = next((k for k in jwks["keys"] if k["kid"] == header["kid"]), None)
        if key is None:
            raise HTTPException(status_code=401, detail="Unknown signing key")

        claims = jwt.decode(
            token,
            key,
            algorithms=["RS256"],
            audience=settings.cognito_client_id,
            issuer=(
                f"https://cognito-idp.{settings.aws_region}.amazonaws.com/"
                f"{settings.cognito_user_pool_id}"
            ),
        )
    except JWTError as exc:
        raise HTTPException(status_code=401, detail=f"Invalid token: {exc}") from exc

    if claims.get("token_use") != "access" and "sub" not in claims:
        raise HTTPException(status_code=401, detail="Unexpected token type")

    groups = tuple(claims.get("cognito:groups", ()))
    tier = next((g for g in groups if g in {"free", "pro", "enterprise"}), "free")

    return Principal(
        sub=claims["sub"], email=claims.get("email"), tier=tier, groups=groups
    )
