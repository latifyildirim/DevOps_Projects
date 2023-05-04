FROM python:alpine

# Uygulama kodunu image'a ekle
COPY . /app
WORKDIR /app 

# Uygulama gereksinimlerini yükle
RUN pip install -r requirements.txt

# Port 80'i aç
EXPOSE 80

# Uygulamayı çalıştır
CMD ["python", "app.py"]
