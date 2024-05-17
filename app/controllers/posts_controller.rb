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


  # GET /posts or /posts.json
  def index
    @posts = Post.all
  end

  # GET /posts/1 or /posts/1.json
  def show
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts or /posts.json
  def create
    @post = Post.new(post_params)

    respond_to do |format|
      if @post.save
        format.html { redirect_to post_url(@post), notice: "Post was successfully created." }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1 or /posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to post_url(@post), notice: "Post was successfully updated." }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1 or /posts/1.json
  def destroy
    @post.destroy!

    respond_to do |format|
      format.html { redirect_to posts_url, notice: "Post was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def post_params
      params.require(:post).permit(:title, :content)
    end
end
