FROM python:3.10-slim
WORKDIR /app

COPY requirements.txt .

RUN python -m pip install --upgrade pip setuptools wheel

RUN pip install torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cpu
RUN grep -v '^torch==' requirements.txt | pip install --no-cache-dir -r /dev/stdin

#RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000
# from 8080

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]