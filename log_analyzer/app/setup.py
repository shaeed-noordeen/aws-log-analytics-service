from setuptools import setup, find_packages

setup(
    name="log_analyzer",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "boto3",
        "fastapi",
        "uvicorn[standard]",
        "httpx>=0.24",
    ],
    entry_points={
        "console_scripts": [
            "analyze = app.cli:main",
        ],
    },
)
