class PersonasController < ApplicationController

  def show
    @persona = Persona.find(params[:id])
	@proyecto = @persona.proyecto
  end
  
  def create
    @proyecto = Proyecto.find(params[:proyecto_id])
	@persona = @proyecto.personas.create(params[:persona])
    redirect_to @persona
  end
 
  def edit
    @persona = Persona.find(params[:id])
	@proyecto = @persona.proyecto
  end

  def update
	@persona = Persona.find(params[:id])
	if @persona.update_attributes(params[:persona])
      redirect_to @persona, :notice  => "Persona actualizada exitosamente"
    else
      render :action => 'edit'
    end
  end

  def destroy
    @persona = Persona.find(params[:id])
    @proyecto = @persona.proyecto
    @persona.destroy
    redirect_to proyecto_path(@proyecto)
  end
end
