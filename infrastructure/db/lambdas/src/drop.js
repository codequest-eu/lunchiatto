const { Client } = require("pg")
const escape = require("pg-escape")

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
    console.log(`Closing connections to database ${environment.db}`)
    await masterClient.query(
      `
      SELECT pg_terminate_backend(pid)
      FROM pg_stat_activity
      WHERE datname = $1 AND pid <> pg_backend_pid()
      `,
      [environment.db]
    )

    console.log(`Dropping database ${environment.db}`)
    await masterClient.query(`DROP DATABASE ${id(environment.db)}`)

    console.log(`Dropping role ${environment.user}`)
    await masterClient.query(`DROP ROLE ${id(environment.user)}`)
  } finally {
    await masterClient.end()
  }

  console.log(`Dropped database ${environment.db} and role ${environment.user}`)
}

exports.handler = handler
