# Market API

## `POST /api/content`

This endpoint can accept two kinds of request bodies:

JSON, with `file` property as the base64 encoded string of the file to be uploaded.

```json
{
  "file": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
  "content_type": "png",
  "sender_id": 123,
  "receiver_id": 456,
  "is_payable": true
}
```

Multipart form data with the following fields:

- `file` - The file to be uploaded
- `content_type` - The file type of the file to be uploaded
- `sender_id` - The ID of the sender
- `receiver_id` - The ID of the receiver
- `is_payable` - Whether or not the file is payable

## `GET /api/user/:user_id/content/purchased`

Returns a list of all the content the user with the given ID has purchased.

## `GET /api/user/:user_id/content/received`

Returns a list of all the content the user with the given ID has been sent.

## `GET /api/user/:user_id/content/:content_id`

Returns a single piece of content in the media format it was uploaded in.

## `POST /api/content/:content_id/purchase`

This endpoint marks the content with the given ID as purchased.

The body of the request is a JSON object with the following properties:

```json
{
  "user_id": 123
}
```

If successful, this endpoints returns the following JSON response:

```json
{
    "purchase_id": 4,
    "purchase_token": "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJtYXJrZXQiLCJleHAiOjE2OTU4MTMxNzksImlhdCI6MTY5NTgxMjU3OSwiaXNzIjoibWFya2V0IiwianRpIjoiZDAzODRhMWUtYjRjOS00MjdkLThkYTMtOTJjNWQ3MTczNTU3IiwibmJmIjoxNjk1ODEyNTc4LCJzdWIiOiJwdXJjaGFzZTo1OmNvbnRlbnQ6NTpyZWNlaXZlcjoxMjMiLCJ0eXAiOiJhY2Nlc3MifQ.N-eviNY8SojZIrkg1J-nDTv8fpIP46O010bcoL4FHpHS52ZBroFCOcebZkQSTeBa9pDn-Ng8bPRPlWqsV47-pg",
    "content_id": 3
}
```

Where `purchase_token` is a JWT token with an expiration of 10 minutes. The
client can use this token to complete a purchase.

## `POST /api/purchase/:purchase_id/complete

Completes a purchase. The `purchase_id` is the ID of the purchase that was returned from the `POST /api/content/:content_id/purchase` endpoint.

Headers Required:

```text
X-Purchase-Token: eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJtYXJrZXQiLCJleHAiOjE2OTU4MTMxNzksImlhdCI6MTY5NTgxMjU3OSwiaXNzIjoibWFya2V0IiwianRpIjoiZDAzODRhMWUtYjRjOS00MjdkLThkYTMtOTJjNWQ3MTczNTU3IiwibmJmIjoxNjk1ODEyNTc4LCJzdWIiOiJwdXJjaGFzZTo1OmNvbnRlbnQ6NTpyZWNlaXZlcjoxMjMiLCJ0eXAiOiJhY2Nlc3MifQ.N-eviNY8SojZIrkg1J-nDTv8fpIP46O010bcoL4FHpHS52ZBroFCOcebZkQSTeBa9pDn-Ng8bPRPlWqsV47-pg
```

If successful, a `200` response is given with a JSON payload:

```json
{
    "purchase_id": 4,
}
```
