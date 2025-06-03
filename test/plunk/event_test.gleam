import gleam/hackney
import gleam/io
import gleam/json
import gleam/string
import gleeunit/should
import plunk
import plunk/event.{Event}

// Gleam erlang dropped the "os.get_env" function, so define it here
const key = ""

pub fn track_test() {
  should.not_equal(key, "")

  let req =
    plunk.new(key)
    |> event.track(
      Event(event: "your-event", email: "someone@example.com", data: [
        #("name", json.string("John")),
      ]),
    )

  case hackney.send(req) {
    Ok(resp) -> {
      let d = event.decode(resp)
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
