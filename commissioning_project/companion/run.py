"""Entry point for the Cx companion system."""
import asyncio
from companion.app import Application

if __name__ == "__main__":
    asyncio.run(Application().run())
