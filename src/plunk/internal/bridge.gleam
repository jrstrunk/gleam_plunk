import gleam/dynamic
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/string
import gleam/json
import plunk/types.{ApiError, JSONError, PlunkError}
import plunk/instance.{Instance}

const plunk_url = "https://api.useplunk.com/v1"

pub fn make_request(
  instance: Instance,
  endpoint path: String,
  method method: http.Method,
  body body: String,
) -> Request(String) {
  request.new()
  |> request.set_method(method)
  |> request.set_host(plunk_url)
  |> request.set_path(normalize_path(path))
  |> fn(request) -> Request(String) {
    // we only want to set the body if it's not a GET request
    case method {
      http.Get -> request
      _ -> request.set_body(request, body)
    }
  }
  |> request.set_header("Content-Type", "application/json")
  |> request.set_header("Accept", "application/json")
  |> request.set_header("Authorization", "Bearer" <> instance.api_key)
}

pub fn normalize_path(path: String) -> String {
  let path = case string.starts_with(path, "/") {
    True -> path
    False -> "/" <> path
  }

  case string.ends_with(path, "/") {
    True ->
      path
      |> string.trim
      |> string.drop_right(1)
    False -> path
  }
}

fn error_decoder() -> dynamic.Decoder(PlunkError) {
  dynamic.decode4(
    ApiError,
    dynamic.field("code", of: dynamic.int),
    dynamic.field("error", of: dynamic.string),
    dynamic.field("message", of: dynamic.string),
    dynamic.field("time", of: dynamic.int),
  )
}

pub fn send(
  request: Request(String),
  instance: Instance,
  decoder: fn() -> dynamic.Decoder(t),
) -> Result(t, PlunkError) {
  let Response(status: status, body: body, ..) =
    instance
    |> instance.send(request)

  case status {
    status if status >= 200 && status < 300 -> {
      case json.decode(from: body, using: decoder()) {
        Ok(decoded) -> Ok(decoded)
        Error(err) -> Error(JSONError(err))
      }
    }
    _ -> {
      case json.decode(from: body, using: error_decoder()) {
        Ok(decoded) -> Error(decoded)
        Error(err) -> Error(JSONError(err))
      }
    }
  }
}
