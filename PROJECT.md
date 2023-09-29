# Kivra Technical Assessment

Company K wants to create a digital infrastructure to allow content producers to send content to the users of company K.

There is a content producer that is interested in enrolling for a proof of concept and your task is to implement the backend parts of the system and propose a solution for the hosting of the service(s).

The backend should be composed of 2 APIs:

- Sender API for content producers
- Consumer API for user facing applications

The sender API accepts files in binary format and some metadata that contains:

- `sender_id` (integer)
- `content_type` (string)
- `receiver_id` (integer)
- `is_payable` (boolean)

The Consumer API allows to query content by sender_id and if the content is payable the API should be able to trigger a payment.

The actual payment processing is outside of the scope of this exercise, so if the payment is triggered the content should actually be marked as paid.

Your solution it’s supposed to be a proof of concept but the customer has the following requirements:

- Can’t lose data
- Content should be available for the users to read within 1 hour after it was sent
- Sender wants to send data in batches so peaks of 50 requests per second should be expected

Your solution doesn’t need to be complete and ready to go to production, but we expect that you have at least started to implement and are ready to present and continue implement it during the interview so make sure to bring your laptop with the code.
