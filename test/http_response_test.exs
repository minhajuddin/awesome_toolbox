defmodule AwesomeToolbox.HTTPResponseTest do
  use ExUnit.Case

  alias HTTP.Response
  import Response

  test "parses a status message" do
    ref = make_ref()

    assert {:ok, %Response{status_code: 200, complete?: false}} =
             parse(
               [
                 {:status, ref, 200}
               ],
               ref
             )
  end

  test "parses a headers message" do
    ref = make_ref()

    assert {:ok,
            %Response{
              status_code: 300,
              complete?: false,
              headers: [{"content-type", "text/html"}]
            }} =
             parse(
               [
                 {:headers, ref, [{"content-type", "text/html"}]}
               ],
               ref,
               %Response{status_code: 300}
             )
  end

  test "parses a data message" do
    ref = make_ref()

    assert {:ok, %Response{status_code: 200, complete?: false, body: ["iolist"]}} =
             parse(
               [
                 {:data, ref, "iolist"}
               ],
               ref,
               %Response{status_code: 200}
             )
  end

  test "parses multiple data messages" do
    ref = make_ref()

    assert {:ok, %Response{body: ["iolist1", "iolist2"], complete?: true}} =
             parse(
               [
                 {:data, ref, "iolist1"},
                 {:data, ref, "iolist2"},
                 {:done, ref}
               ],
               ref
             )
  end

  test "parses multiple messages for a full response" do
    ref = make_ref()

    assert {:ok,
            %Response{
              status_code: 200,
              headers: [{"content-type", "text/html"}],
              body: ["iolist1", "iolist2", "iolist3"],
              complete?: true
            }} =
             parse(
               [
                 {:status, ref, 200},
                 {:headers, ref, [{"content-type", "text/html"}]},
                 {:data, ref, "iolist1"},
                 {:data, ref, "iolist2"},
                 {:data, ref, "iolist3"},
                 {:done, ref}
               ],
               ref
             )
  end

  test "returns an error for invalid ref" do
    assert {:error, :invalid_ref} =
             parse(
               [
                 {:status, make_ref(), 200}
               ],
               make_ref()
             )

    assert {:error, :invalid_ref} =
             parse(
               [
                 {:done, make_ref()}
               ],
               make_ref()
             )
  end
end
