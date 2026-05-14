import logging
from pathlib import Path

class Logger:
    def __init__(self, log_file: str = "app.log"):
        self.log_path = Path(log_file)
        self.logger = logging.getLogger("app")
        self.logger.setLevel(logging.DEBUG)
        handler = logging.FileHandler(self.log_path, encoding="utf-8")
        formatter = logging.Formatter("%(asctime)s %(levelname)s %(message)s")
        handler.setFormatter(formatter)
        self.logger.addHandler(handler)

    def info(self, msg: str):
        self.logger.info(msg)

    def error(self, msg: str):
        self.logger.error(msg)
