defmodule JSONAPI.API do
  @moduledoc """
    JSON:API API Configuration

    You can define an API by calling `use JSONAPI.API` in your module

    ```elixir
    defmodule MyApp.API do
      use JSONAPI.API, otp_app: :my_app
    end
    ```

    API module behavior can be customized via your application configuration:

    ```elixir
    config :my_app, MyApp.API,
      namespace: "api",
      case: :dasherize
    ```
  """

  alias JSONAPI.Pagination

  @options_schema [
    otp_app: [
      doc: "OTP application to use for API configuration.",
      type: :atom,
      required: true
    ]
  ]

  @config_schema [
    case: [
      doc:
        "This option controls how your API's field names will be cased. The current [JSON:API Spec (v1.0)](https://jsonapi.org/format/1.0/) recommends dasherizing (e.g. `\"favorite-color\": \"blue\"`), while the upcoming [JSON:API Spec (v1.1)](https://jsonapi.org/format/1.1/) recommends camelCase (e.g. `\"favoriteColor\": \"blue\"`)",
      type: {:in, [:camelize, :dasherize, :underscore]},
      default: :camelize
    ],
    host: [
      doc: "Hostname used for link generation instead of deriving it from the connection.",
      type: :string
    ],
    namespace: [
      doc:
        "Namespace for all resources in your API. if you want your resources to live under \".../api/v1\", pass `namespace: \"api/v1\"`.",
      type: :string
    ],
    normalizer: [
      doc: "Normalizer for transformation of JSON:API document to and from user data",
      type: :atom,
      default: JSONAPI.Normalizer.Ecto
    ],
    query_parsers: [
      doc: "Normalizer for transformation of JSON:API document to and from user data",
      type: :keyword_list,
      keys: [
        filter: [doc: "Filter parser", type: :atom, default: JSONAPI.QueryParser.Filter],
        page: [doc: "Page parser", type: :atom, default: JSONAPI.QueryParser.Page],
        sort: [doc: "Sort parser", type: :atom, default: JSONAPI.QueryParser.Ecto.Sort]
      ],
      default: [
        filter: JSONAPI.QueryParser.Filter,
        page: JSONAPI.QueryParser.Page,
        sort: JSONAPI.QueryParser.Ecto.Sort
      ]
    ],
    pagination: [
      doc: "A module adopting the `JSONAPI.Pagination` behaviour for pagination.",
      type: :atom,
      default: nil
    ],
    port: [
      doc: "Port used for link generation instead of deriving it from the connection.",
      type: :pos_integer
    ],
    scheme: [
      doc: "Scheme used for link generation instead of deriving it from the connection.",
      type: {:in, [:http, :https]}
    ],
    version: [
      doc: "[JSON:API](https://jsonapi.org) version advertised in the document",
      type: {:in, [:"1.0"]},
      default: :"1.0"
    ]
  ]

  @type t :: module()

  @type case :: JSONAPI.case()
  @type host :: String.t()
  @type namespace :: String.t()
  @type pagination :: Pagination.t()
  @type http_port :: pos_integer()
  @type scheme :: :http | :https
  @type version :: :"1.0"

  defmacro __using__(options) do
    {otp_app, _options} =
      options
      |> NimbleOptions.validate!(@options_schema)
      |> Keyword.pop(:otp_app)

    quote do
      @__otp_app__ unquote(otp_app)
      def __otp_app__, do: @__otp_app__
    end
  end

  @doc """
  Retrieve a configuration parameter

  Retrieves an API configuration parameter value, with fallback to a default value
  in case the configuration parameter is not present.

  Available options are:
  #{NimbleOptions.docs(@config_schema)}
  """
  @spec get_config(t() | nil, [atom()], any()) :: any()
  def get_config(api, path, default \\ nil)

  def get_config(nil = _api, _path, default), do: default

  def get_config(api, path, default) do
    api
    |> get_all_config()
    |> NimbleOptions.validate!(@config_schema)
    |> get_in(path) || default
  end

  defp get_all_config(api) do
    api.__otp_app__()
    |> Application.get_env(api, [])
  end
end
