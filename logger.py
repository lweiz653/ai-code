import logging
import os
import sys
from typing import Optional

class LoggerService:
    """Simple logger service providing named loggers.

    The logger is configured on first use with a stream handler writing to
    ``sys.stdout``.  If the ``LOG_FILE`` environment variable is set, a file
    handler is also attached.  The log level can be overridden via the
    ``LOG_LEVEL`` environment variable (defaults to ``INFO``).
    """

    _loggers = {}
    _formatter = logging.Formatter(
        fmt="%(asctime)s - %(levelname)s - %(name)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    @classmethod
    def get_logger(cls, name: str) -> logging.Logger:
        """Return a configured logger with the given *name*.

        The logger is cached so repeated calls with the same name return the
        identical ``logging.Logger`` instance.
        """
        if name in cls._loggers:
            return cls._loggers[name]

        logger = logging.getLogger(name)
        # Prevent propagation to root handlers which could duplicate output.
        logger.propagate = False
        level_name = os.getenv("LOG_LEVEL", "INFO").upper()
        logger.setLevel(getattr(logging, level_name, logging.INFO))

        # Stream handler (stdout)
        stream_handler = logging.StreamHandler(sys.stdout)
        stream_handler.setFormatter(cls._formatter)
        logger.addHandler(stream_handler)

        # Optional file handler
        log_file: Optional[str] = os.getenv("LOG_FILE")
        if log_file:
            file_handler = logging.FileHandler(log_file)
            file_handler.setFormatter(cls._formatter)
            logger.addHandler(file_handler)

        cls._loggers[name] = logger
        return logger

# Convenience function for module‑level access
def get_logger(name: str) -> logging.Logger:
    """Shortcut to ``LoggerService.get_logger``.
    """
    return LoggerService.get_logger(name)
