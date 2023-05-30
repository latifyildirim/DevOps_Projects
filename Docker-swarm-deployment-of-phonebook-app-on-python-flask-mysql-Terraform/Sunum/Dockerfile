FROM python:alpine
WORKDIR /app    # Burada /app dosyasi altinda calisir
COPY requirements.txt requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 80
CMD [ "python", "phonebook-app.py" ]