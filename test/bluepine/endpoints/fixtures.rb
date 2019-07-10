module BluepineApiEndpointFixtures
  def resolver
    endpoints = [
      create_endpoint("/accounts/:account", schema: :account) do
        get :index, path: "/:id"
      end,

      create_endpoint("/charges", schema: :charge) do
        get  :index, path: "/", as: :list
        get  :show, path: "/:id"
        post :create, path: "/", params: lambda {
          integer :amount, required: true
        }
        patch :update, path: "/", params: lambda {
          string :currency, required: true
        }
      end,
    ]

    schemas = [
      create_schema(:charge) do
        string  :object, default: :charge, match: :charge
        integer :amount
        string  :currency
      end,

      create_schema(:list) do
        string :object, default: :list, match: :list
        array  :data
      end,
    ]

    create_resolver(
      schemas: schemas,
      endpoints: endpoints,
    )
  end
end
