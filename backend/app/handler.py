"""AWS Lambda entrypoint. Mangum adapts the ASGI app to the Lambda event model."""
from mangum import Mangum

from app.main import app

handler = Mangum(app, lifespan="off")
