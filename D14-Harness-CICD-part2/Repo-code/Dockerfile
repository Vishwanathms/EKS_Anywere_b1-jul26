FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 5000

CMD ["newrelic-admin", "run-program", "python", "app.py"]

#CMD ["python", "app.py"]
