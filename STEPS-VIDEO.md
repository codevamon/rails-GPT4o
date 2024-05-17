### Pasos tutorial

#### 1. Configuración del Proyecto

```bash
# Crear un nuevo proyecto Rails
rails new TextEnhancer
cd TextEnhancer

# Añadir en el gemfile
gem 'openai', '~> 0.3.0'
gem 'ruby-openai', '~> 6.3'

# Instalar las gemas
bundle install
```

#### 2. Creacion del modelo
```bash
# Crea el schema de base de datos
rake db:create
# Generar un scaffold para un modelo simple
rails generate scaffold Post title:string content:text
rails db:migrate
```

#### 3. Integración con OpenAI

- Configura la gema OpenAI añadiendo tu API Key.

```ruby
# Crear el archivo config/initializers/openai.rb
OpenAI.configure do |config|
    config.access_token = ENV.fetch("OPENAI_ACCESS_TOKEN")
end
```
#### 4. Logica de peticion para OpenAI
- Modificar el controlador de posts para agregar la funcionalidad de mejora de texto les recomiendo este codigo lo lleven a un servicio o modulo aparte, pero por practicidad para el video lo agregare al controller.

```ruby
# app/controllers/posts_controller.rb
require 'openai'

class PostsController < ApplicationController
  before_action :set_post, only: %i[ show edit update destroy improve ]

  # Acción para mejorar el texto
  def improve
    client = OpenAI::Client.new

    response = client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [
          { role: "system", content: <<~INSTRUCTION.strip },
            **Mejora tus títulos y contenido para que destaquen en la plataforma web.** A continuación te doy las instrucciones detalladas:

            1. **Crear títulos descriptivos, llamativos y concisos:** Asegúrate de que los títulos capturen la atención de los usuarios y transmitan claramente el mensaje.

            2. **Corregir errores gramaticales y mejorar la legibilidad:** Mejora la gramática y haz que el texto sea fácil de entender.

            3. **Agregar información valiosa adicional:** Si el usuario está describiendo un producto conocido, como un auto o cualquier producto del cual dispongas informacion que ayude a expandir lo que el user te envia, añade características generales y beneficios de ese tipo de producto. Esta información adicional debe potenciar la descripción original del usuario. es decir si en el mensaje del rol user en su campo content habla de unas caracteristicas de un prodcuto x para venderlo agrega por favor los beneficios que conozcan de manera que ayude a venderlo.

            4. **Responder en el mismo idioma del usuario:** Asegúrate de responder en el mismo idioma en el que el usuario escribe, es decir a pesar de que estas instrucciones estan en español analiza el mensaje del rol user en su campo content en caso de estar en otro idioma responde en ese idioma.

            5. **Respuesta directa sin encabezados adicionales:** Tu respuesta se insertará directamente en los formularios, así que responde sin encabezados como "Título Mejorado:" o similares.

          INSTRUCTION
          { role: "user", content: @post.content }
        ],
        max_tokens: 250 # Limita la respuesta a un máximo de 150 tokens
      }
    )

    improved_content = response["choices"].first["message"]["content"]
    limited_content = improved_content[0..499]

    @post.update(content: limited_content)
    redirect_to @post, notice: "El texto ha sido mejorado."
  end

```
#### 5. Configuracion de ruta
- Añadir la ruta para la nueva acción.

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root "posts#index"

  resources :posts do
    member do
      post :improve
    end
  end
end
```

#### 6. Agregar Tailwind por cdn
En el app/views/layouts/application.html.erb para production no se recomienda usar cdn
```ruby
<script src="https://cdn.tailwindcss.com"></script>
```

#### 7. Configuración del Frontend con Tailwind

- Ahora a modificar las vistas de post para añadir un botón de mejora de texto.
- En app/views/posts/_post.html.erb
```erb
  <div id="<%= dom_id post %>" class="mx-auto md:w-2/3 w-full flex flex-col items-center bg-gray-800 text-white p-6 rounded-lg shadow-lg my-4">
    <div class="w-full">
      <div class="mb-4">
        <h2 class="text-2xl font-bold mb-2">Title:</h2>
        <p class="text-xl"><%= post.title %></p>
      </div>

      <div class="mb-4">
        <h2 class="text-2xl font-bold mb-2">Content:</h2>
        <p class="text-lg"><%= post.content %></p>
      </div>

      <div class="flex space-x-4 mt-4">
        <%= link_to "Show this post", post, class: "bg-cyan-500 hover:bg-cyan-700 text-white font-bold py-2 px-4 rounded transition duration-200" %>
        <%= link_to 'Edit', edit_post_path(post), class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded transition duration-200" %>

        <%= button_to 'Improve Text', improve_post_path(post), method: :post, class: "bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded transition duration-200" %>
      </div>
    </div>
  </div>
```

- app/views/posts/_form.html.erb
```erb
<%= form_with(model: post, class: "w-full max-w-lg mx-auto text-white p-6 rounded-lg ") do |form| %>
  <% if post.errors.any? %>
    <div id="error_explanation" class="bg-red-600 text-white px-4 py-3 mb-5 font-medium rounded-lg">
      <h2><%= pluralize(post.errors.count, "error") %> prohibited this post from being saved:</h2>
      <ul class="list-disc list-inside">
        <% post.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="my-4">
    <%= form.label :title, class: "block text-lg font-medium mb-2" %>
    <%= form.text_field :title, class: "block shadow rounded-md border border-gray-600 bg-gray-700 text-white outline-none px-3 py-2 mt-2 w-full focus:ring-2 focus:ring-blue-500" %>
  </div>

  <div class="my-4">
    <%= form.label :content, class: "block text-lg font-medium mb-2" %>
    <%= form.text_area :content, rows: 4, class: "block shadow rounded-md border border-gray-600 bg-gray-700 text-white outline-none px-3 py-2 mt-2 w-full focus:ring-2 focus:ring-blue-500" %>
  </div>

  <div class="flex justify-end mt-6">
    <%= form.submit 'Save', class: "rounded-lg py-3 px-5 bg-blue-600 hover:bg-blue-700 text-white font-medium cursor-pointer transition duration-200" %>
  </div>
<% end %>

```
- app/views/posts/index.html.erb
```erb
<div class="w-full max-w-4xl mx-auto">
  <% if notice.present? %>
    <p class="py-2 px-3 bg-green-600 text-white mb-5 font-medium rounded-lg inline-block" id="notice"><%= notice %></p>
  <% end %>

  <div class="flex justify-between items-center mb-6">
    <h1 class="font-bold text-4xl text-white">Posts</h1>
    <%= link_to "New post", new_post_path, class: "rounded-lg py-3 px-5 bg-blue-600 hover:bg-blue-700 text-white block font-medium transition duration-200" %>
  </div>

  <div id="posts" class="grid gap-6">
    <% @posts.each do |post| %>
      <%= render post %>
    <% end %>
  </div>
</div>
```
- app/views/posts/show.html.erb
```erb
<div class="mx-auto md:w-2/3 w-full flex">
  <div class="mx-auto">
    <% if notice.present? %>
      <p class="py-2 px-3 bg-green-50 mb-5 text-green-500 font-medium rounded-lg inline-block" id="notice"><%= notice %></p>
    <% end %>

    <div class="mb-4">
      <%= render @post %>
      <%= link_to 'Back', posts_path, class: "bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded transition duration-200" %>
    </div>

  </div>
</div>
```