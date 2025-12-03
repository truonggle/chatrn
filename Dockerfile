FROM rayproject/ray:2.52.0-py310-cpu

WORKDIR /app

COPY /app /app/app/
COPY /models /app/models/

RUN pip install torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cpu
RUN grep -v '^torch==' /app/app/backend/requirements.txt | pip install --no-cache-dir -r /dev/stdin

ENV PYTHONPATH=/app