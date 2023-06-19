FROM apache/superset
# Switching to root to install the required packages
USER root
WORKDIR /app
# Example: installing the MySQL driver to connect to the metadata database
# if you prefer Postgres, you may want to use `psycopg2-binary` instead
# Example: installing a driver to connect to Redshift
# Find which driver you need based on the analytics database
# you want to connect to here:
# https://superset.apache.org/installation.html#database-dependencies
COPY logo.png /app/superset/static/assets/images/logo.png
COPY logo_favicon.png /app/superset/static/assets/images/logo_favicon.png

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
# Switching back to using the `superset` user
USER superset