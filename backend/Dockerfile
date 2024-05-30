FROM python:3.11

WORKDIR /app

COPY ./requirements.txt .

RUN python -m pip install --upgrade pip

RUN pip3 install -r requirements.txt

COPY . .

CMD ["gunicorn", "green_blue.wsgi:application", "--bind", "0.0.0.0:8000"]