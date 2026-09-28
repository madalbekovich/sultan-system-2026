from fastapi import APIRouter, HTTPException, status

from app.core.security import create_access_token
from app.schemas.auth import LoginRequest, TokenResponse

router = APIRouter(prefix="/auth", tags=["auth"])

# TODO: replace with a real staff/user table once roles (worker/manager) are defined.
_STAFF_CREDENTIALS = {"admin": "admin"}


@router.post("/", response_model=TokenResponse)
async def login(payload: LoginRequest) -> TokenResponse:
    expected_password = _STAFF_CREDENTIALS.get(payload.username)
    if expected_password is None or expected_password != payload.password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials"
        )
    token = create_access_token(subject=payload.username)
    return TokenResponse(access_token=token)
