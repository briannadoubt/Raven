"""
Setup for Raven CLI
"""

from setuptools import setup, find_packages
from pathlib import Path

# Read README
readme_file = Path(__file__).parent / "README.md"
long_description = readme_file.read_text() if readme_file.exists() else ""

setup(
    name="raven-cli",
    version="0.1.0",
    description="Development tools for Raven Swift WASM apps",
    long_description=long_description,
    long_description_content_type="text/markdown",
    author="Raven Team",
    url="https://github.com/yourusername/Raven",
    packages=['cli'],
    python_requires=">=3.8",
    install_requires=[
        "click>=8.0.0",
        "flask>=3.0.0",
        "flask-cors>=4.0.0",
        "watchdog>=3.0.0",
    ],
    entry_points={
        "console_scripts": [
            "raven=raven:main",
        ],
    },
    scripts=['raven'],
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "Topic :: Software Development :: Build Tools",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
)
