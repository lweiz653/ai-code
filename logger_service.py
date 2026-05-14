"""Simple Logger Service.

Provides a singleton :class:`LoggerService` that wraps the standard :mod:`logging` module.
It configures a console handler with a simple format and INFO level by default.
Users can obtain the underlying :class:`logging.Logger` via ``logger`` attribute.
"""

import logging
from typing import Optional

class LoggerService:
    """Singleton logger service.

    Example
    -------
    >>> from logger_service import logger_service
    >>> logger = logger_service.logger
    >>> logger.info("Hello")
    """

    _instance: Optional["LoggerService"] = None

    def __new__(cls) -> "LoggerService":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self) -> None:
        # Initialize only once
        if getattr(self, "_initialized", False):
            return
        self._logger = logging.getLogger("logger_service")
        self._logger.setLevel(logging.INFO)
        if not self._logger.handlers:
            handler = logging.StreamHandler()
            formatter = logging.Formatter(
                "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
            )
            handler.setFormatter(formatter)
            self._logger.addHandler(handler)
        self._initialized = True

    @property
    def logger(self) -> logging.Logger:
        """Return the configured :class:`logging.Logger`."""
        return self._logger

# Export a ready‑to‑use singleton instance
logger_service = LoggerService()

__all__ = ["LoggerService", "logger_service"]
