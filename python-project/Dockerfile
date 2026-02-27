FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir requests

COPY ETL.py .

CMD ["python", "ETL.py"]
