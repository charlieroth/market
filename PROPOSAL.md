# Assessment Proposal

## Hosting

I would host the service on Google Cloud Platform (GCP) using the following services:

- Cloud Run for the API
- Cloud SQL for the database (PostgreSQL)
- Cloud Storage for the file storage

## Architectural Notes

In the proof-of-concept stage, I would keep the Sender API and Consumer API
in the same application. I would also store the files in a PostgreSQL table
using the `bytea` data type. This would allow for a simpler infrastructure
and deployment process. If the proof-of-concept were to be successful, I would
consider splitting the APIs into separate applications. This would allow for
more flexibility in scaling the APIs independently.

For example, since the Sender API is responsible for processing and handling
file uploads the API will likely have different performance requirements and
may even require different technology than what was used to build the prototype.

Another example, the Consumer API would likely be more read-heavy and could be
scaled by replicating the database.
