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