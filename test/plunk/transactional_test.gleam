import gleam/hackney
import gleam/io
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import plunk
import plunk/transactional.{Address, TransactionalEmail}

// Gleam erlang dropped the "os.get_env" function, so define it here
const key = ""

pub fn send_test() {
  should.not_equal(key, "")

  let req =
    plunk.new(key)
    |> transactional.send(mail: TransactionalEmail(
      to: Address("someone@mailinator.com"),
      subject: "Hello",
      body: "Hello, World!",
      name: Some("plunk.gleam"),
      from: None,
    ))

  case hackney.send(req) {
    Ok(resp) -> {
      let d = transactional.decode(resp)
      should.be_ok(d)
      let assert Ok(data) = d
      should.equal(data.success, True)
      io.println_error(data |> string.inspect)
      Nil
    }
    Error(e) -> {
      io.println_error(e |> string.inspect)
      should.fail()
    }
  }
}
