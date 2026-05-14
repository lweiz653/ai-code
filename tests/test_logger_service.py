"""Tests for the LoggerService implementation."""

import sys, os
import logging
import unittest

# Ensure the repository root is on sys.path for imports
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from logger_service import logger_service


class TestLoggerService(unittest.TestCase):
    def test_logger_is_configured(self):
        """The logger should be an instance of ``logging.Logger`` and have a handler."""
        logger = logger_service.logger
        self.assertIsInstance(logger, logging.Logger)
        self.assertTrue(any(isinstance(h, logging.StreamHandler) for h in logger.handlers))

    def test_singleton_behavior(self):
        """Importing the service twice should return the same underlying logger instance."""
        from logger_service import logger_service as ls2
        self.assertIs(logger_service, ls2)
        self.assertIs(logger_service.logger, ls2.logger)
