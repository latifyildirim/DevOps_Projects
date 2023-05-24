FROM python:alpine
COPY requirements.txt app/requirements.txt
WORKDIR /app
RUN pip3 install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 80
CMD ["python", "app.py"]
