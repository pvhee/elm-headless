import Http
import Html exposing (Html, h1, h2, button, div, text, ul, li)
import Html.App as Html
import Html.Events exposing (onClick)
import Time exposing (Time)
import Json.Decode as JD exposing ((:=))
import String exposing (toInt, toFloat)
import Task


-- MAIN

main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

headlessServer : String
headlessServer =
  --"http://campaign.lab/api/node/article?_format=api_json"
  "http://localhost:3000/db"

type alias Id = Int

type alias Article =
  --{ author : Author
  { body : String
  , id : Id
  --, image : Maybe String
  --, image : String
  , label : String
  }

type alias Author =
  { id : Id
  , name : String
  }

type Status =
  Init
  --| Fetching
  --| Fetched Time.Time
  --| HttpError Http.Error


type alias Model =
  { articles : List Article
  , status : Status
  , error : String
  }

initialModel : Model
initialModel =
  --Model [ Article (Author 1 "peter") "This is the body" 1 "" "First article" ] Init ""
  Model [ Article "This is the body" 1 "First article" ] Init ""

init : (Model, Cmd Msg)
init =
  (initialModel, fetch)

-- UPDATE

type Msg
  = FetchAllDone (List Article)
  | FetchAllFail Http.Error


update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    FetchAllDone articles->
      -- todo update the status to Done now, not Init anymore
      (Model articles Init "", Cmd.none)
    FetchAllFail error ->
      ({model | error = (toString error)}, Cmd.none)


fetch : Cmd Msg
fetch =
    Http.get decodeData headlessServer
        |> Task.perform FetchAllFail FetchAllDone

-- DECODERS

decodeArticle : JD.Decoder Article
decodeArticle =
  let
    -- Cast String to Int.
    number : JD.Decoder Int
    number =
      JD.oneOf [ JD.int, JD.customDecoder JD.string String.toInt ]

    numberFloat : JD.Decoder Float
    numberFloat =
      JD.oneOf [ JD.float, JD.customDecoder JD.string String.toFloat ]

    decodeId =
      JD.at [""]

    decodeAuthor =
      JD.object2 Author
        ("id" := number)
        ("label" := JD.string)

    decodeImage =
      JD.at ["styles"]
        ("thumbnail" := JD.string)

    decodeBody =
      JD.at ["value"]
        ("value" := JD.string)

  in
    JD.object3 Article
      --("user" := decodeAuthor)
      --(JD.oneOf [ "body" := JD.string, JD.succeed "" ])
      ("body" := ("value" := JD.string))
      ("nid" := number)
      --("image" := JD.string)
      --(JD.maybe ("image" := decodeImage))
      ("title" := JD.string)

decodeData : JD.Decoder (List Article)
decodeData =
  JD.at [ "data" ] <| JD.list <| JD.at [ "attributes" ] <| decodeArticle



-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

-- VIEW

view : Model -> Html Msg
view model =
  div []
    [ h2 [] [ text "Latest articles" ]
    , viewArticles model.articles
    , div [] [ text model.error ]
    ]

viewArticles : List Article -> Html Msg
viewArticles articles =
  ul []
    (List.map viewArticle articles)

viewArticle : Article -> Html Msg
viewArticle article =
  li []
    [ text article.label ]