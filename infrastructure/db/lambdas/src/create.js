const { Client } = require("pg")
const { literal } = require("pg-escape")

function id(value) {
  return `"${value.replace(/"/g, '""')}"`
}

async function handler(event) {
  const { db, master, environment } = event

  const masterClientOptions = {
    host: db.host,
    port: db.port,

    user: master.user,
    password: master.password,
    database: master.db,
  }
  const masterClient = new Client(masterClientOptions)

  console.log("Connecting to master DB...")
  await masterClient.connect()

  try {
    console.log(`Creating role ${environment.user}`)
    await masterClient.query(
      `CREATE ROLE ${id(environment.user)} WITH LOGIN PASSWORD ${literal(
        environment.password
      )}`
    )

    console.log(`Creating database ${environment.db}`)
    await masterClient.query(`CREATE DATABASE ${id(environment.db)}`)

    console.log(`Granting master all rights to ${environment.db}`)
    await masterClient.query(
      `GRANT ALL ON DATABASE ${id(environment.db)} to ${id(master.user)}`
    )

    console.log(`Granting ${environment.user} all rights to ${environment.db}`)
    await masterClient.query(
      `GRANT ALL ON DATABASE ${id(environment.db)} to ${id(environment.user)}`
    )
  } finally {
    await masterClient.end()
  }

  const environmentClient = new Client({
    ...masterClientOptions,
    database: environment.db,
  })

  console.log(`Connecting to ${environment.db}...`)
  await environmentClient.connect()

  try {
    console.log(`Enabling necessary extensions on ${environment.db}`)
    await Promise.all(
      ["pgcrypto", "plpgsql", "uuid-ossp"].map(ext =>
        environmentClient.query(`CREATE EXTENSION IF NOT EXISTS ${id(ext)}`)
      )
    )
  } finally {
    await environmentClient.end()
  }

  console.log(
    `Created database ${environment.db} and role ${environment.user} with access to it`
  )
}

exports.handler = handler
