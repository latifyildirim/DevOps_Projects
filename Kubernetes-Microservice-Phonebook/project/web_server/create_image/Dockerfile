FROM python:alpine
COPY requirements.txt .

# Uygulama gereksinimlerini yükle
RUN pip install -r requirements.txt

# Uygulama kodunu image'a ekle
WORKDIR /app
COPY . .


# Uygulamayı çalıştır
CMD ["python", "app.py"]

# Port 80'i aç
EXPOSE 80
