# Market

## Description

Market is a Elixir, Phoenix application built for a technical assessment with Kivra for a Senior Backend Engineer position.

## Getting Started

### Database

`Market` uses PostgreSQL as its database. The easiest way to get started is to use Docker Desktop. You can find instructions to get PostgreSQL running in Docker [here](https://www.docker.com/blog/how-to-use-the-postgres-docker-official-image/).

Once you are setup, you can start the PostgreSQL server in Docker Desktop.

### Application

To start the API:

```bash
$ git clone https://github.com/charlieroth/market.git

$ cd market

$ mix setup

$ iex -S mix phx.server
```

API is now available at [`http://localhost:4000/api`](http://localhost:4000/api).

### API Endpoints

#### `POST /api/upload`

This endpoint can accept two kinds of requests:

JSON request with the following body. The `file` property is the base64 encoded string of the file to be uploaded.

```json
{
  "file": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
  "file_type": "png",
  "sender_id": 123,
  "receiver_id": 456,
  "is_payable": true
}
```

Multipart form data with the following fields:

- `file` - The file to be uploaded
- `file_type` - The file type of the file to be uploaded
- `sender_id` - The ID of the sender
- `receiver_id` - The ID of the receiver
- `is_payable` - Whether or not the file is payable

#### `GET /api/content/sender/:sender_id`

This endpoint returns a list of all the files uploaded by the sender with the given ID.

#### `GET /api/content/receiver/:receiver_id`

This endpoint returns a list of all the files uploaded to the receiver with the given ID.

#### `POST /api/content/:content_id/purchase`

This endpoint marks the content with the given ID as purchased.

The body of the request is a JSON object with the following properties:

```json
{
  "receiver_id": 123
}
```

If successful, this endpoints returns the following JSON response:

```json
{
    "purchase_id": 567,
    "purchase_token": "9awrg97qa8w4g7q92847gqw4",
    "content_id": 3
}
```

Where `purchase_token` is a JWT token with an expiration of 10 minutes. The
client can use this token to complete a purchase.

#### `POST /api/purchase/complete/:purchase_id`

This endpoint is used to complete a purchase. The `purchase_id` is the ID of the purchase that was returned from the `POST /api/content/:content_id/purchase` endpoint.

This request requires the purchase token to be sent in the `X-Purchase-Token` header.

If successful, this endpoint returns the following JSON response:

```json
{
    "purchase_id": 567,
    "content_id": 3,
    "receiver_id": 123
}
```

If the purchase token is invalid, this endpoint will return a `401` status code.
