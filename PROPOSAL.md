# Proposal

## Application & Hosting

I would highly recommend building this with Elixir & Phoenix. This would allow
the development team to quickly spin up APIs that leverage best practices
from years of API and systems design. By using Phoenix, you automically use
`Plug` which provides you with almost everything you would need to build a well
architected API. Additionally, `Plug` gives you tools to limit upload sizes
and optimize performance of file uploads (see "Optimizing File Uploads In Regards To System Memory Usage") section

## System Design & Architecture

In the proof-of-concept stage, I would keep the Sender API and Consumer API
in the same application.

In production, I would consider splitting the APIs into separate applications,
allowing for more flexibility in scaling the APIs independently.

For example, since the Sender API is responsible for processing and handling
file uploads the API will likely have different performance requirements and
may even require different technology than what was used to build the prototype.

Another example, the Consumer API would likely be more read-heavy and could be
scaled by replicating the database.

## File Storage

In the proof-of-concept stage, I would also store the files in a PostgreSQL
table using the `bytea` data type. This would allow for a more simple infrastructure
and deployment process.

In production, I would use a blob storage solution such as Amazon S3 or GCP
Cloud Storage. This would also allow you to utilizing the optimized APIs
that these services have developed that have allowed hundreds of companies
to scale up their services to meet much higher demands than 50 req/sec.

## Performance

Elixir can handle the performance requirements specified in the case description
(50 req/sec). You could also easily horizontally scale the system using
a combination of Docker/k8s and the distribution tools built into the BEAM.

You could also architect the application to process uploads in a job processing
manner by either writing your own solution or using a "ready-made" solution
such as [Oban](https://getoban.pro).

### Optimizing File Uploads In Regards To System Memory Usage

The case gives the requirement for allowing a request to be made to the API
with the file as a string/binary. This is fine for the prototype stage and
even in production, however for Elixir applications that use `Plug` this is
not the most efficient way to handle file uploads, especially large files.
In this [article](https://blog.tentamen.eu/how-to-upload-files-in-elixir-phoenix-json-api/)
it was found that by using multi-part form data requests, you can lean on the
work of developers before you and you will receive a `%Plug.Upload{}` struct
in the requests `%Plug.Conn{}`. Per the `Plug.Upload` documentation, "Uploaded
files are stored in a temporary directory and removed from that directory after
the process that requested the file dies". All of this to say, when experiencing
a high volume of file uploads, it might be a good idea to consider using
multi-part form data requests instead.
