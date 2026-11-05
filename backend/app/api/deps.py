from fastapi import Depends, Header, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import decode_access_token
from app.db.session import get_session

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/")
oauth2_scheme_optional = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/", auto_error=False)


async def get_db(session: AsyncSession = Depends(get_session)) -> AsyncSession:
    return session


async def get_current_username(token: str = Depends(oauth2_scheme)) -> str:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_access_token(token)
        username = payload.get("sub")
        if username is None:
            raise credentials_exception
        return username
    except JWTError:
        raise credentials_exception


async def require_bot_or_manager(
    x_bot_key: str | None = Header(default=None),
    token: str | None = Depends(oauth2_scheme_optional),
) -> str:
    """Gate for every endpoint the bot needs that isn't manager-only — the
    endpoint accepts either the bot's shared secret or a manager's JWT.
    Without this, these routes were reachable by anyone on the public
    internet with zero credentials (the actual vulnerability behind the
    "clients can see each other's prices" report, not the pricing model
    itself)."""
    if x_bot_key and x_bot_key == settings.BOT_API_KEY:
        return "bot"
    if token:
        try:
            payload = decode_access_token(token)
            username = payload.get("sub")
            if username:
                return username
        except JWTError:
            pass
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Not authenticated",
        headers={"WWW-Authenticate": "Bearer"},
    )
