FROM python:3.6.0-alpine

COPY ./requirements.txt ./requirements.txt
RUN pip install -r requirements.txt

WORKDIR /app
ADD . /app

ENV POST_DATABASE_HOST post_db_container
ENV POST_DATABASE posts

ENTRYPOINT ["python3", "post_app.py"]
