FROM python:3.12-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
      postgresql-client bash dnsutils curl make ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /stand
COPY python/ /stand/python/
COPY scripts/ /stand/scripts/
COPY sql/ /stand/sql/
RUN pip install --no-cache-dir "psycopg[binary]>=3.1" pytest
ENV PYTHONPATH=/stand/python
CMD ["bash"]
