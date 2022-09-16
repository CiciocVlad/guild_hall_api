defmodule GuildHallWeb.Router do
  use GuildHallWeb, :router
  alias GuildHallWeb.Plugs.{RequireAuthorization, RequireAdmin}

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :profile do
    plug :accepts, ["json"]
  end

  pipeline :require_jwt_authorization do
    plug RequireAuthorization
  end

  pipeline :require_admin do
    plug RequireAdmin
  end

  scope "/api", GuildHallWeb do
    pipe_through :api

    post "/authenticate_with_token", AuthController, :authenticate_with_token

    get "/profile/:mapping", TechnicalProfileController, :show

    pipe_through :require_jwt_authorization

    get "/users", UserController, :list_users
    resources "/users", UserController, except: ~w/index/a
    get "/users/:user_id/roles", UserController, :get_roles
    get "/users/:user_id/technologies", UserController, :get_technologies
    get "/users/:user_id/projects", UserController, :get_projects_of_user

    resources "/projects", ProjectController

    get "/quotes", QuoteController, :index
    get "/articles", ArticleController, :index
    get "/categories", CategoryController, :index
    get "/attributes", AttributeController, :index
    get "/pto", PTOController, :index
    get "/roles", RoleController, :index

    get "/filters", AttributeController, :get_filters

    post "/off-today", UserController, :get_off_today
    get "/remaining-days", UserController, :remaining_days
    get "/remaining-days/:email", UserController, :remaining_days_for_user

    get "/users/:user_id/projects_data", UserController, :get_data_for_projects

    resources "/redirect_urls", RedirectUrlController

    pipe_through :require_admin

    put "/attributes", AttributeController, :update_is_favorite
    resources "/users_projects", UserProjectController, except: ~w[update]a
    put "/pto", PTOController, :update_for_user
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: GuildHallWeb.Telemetry
    end
  end
end
