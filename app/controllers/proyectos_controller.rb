class ProyectosController < ApplicationController
  def index
    @proyectos = Proyecto.all
  end

  def show
    @proyecto = Proyecto.find(params[:id])
  end

  def new
    @proyecto = Proyecto.new
  end

  def create
    @proyecto = Proyecto.new(params[:proyecto])
    if @proyecto.save
      redirect_to @proyecto, :notice => "Proyecto creado exitosamente"
    else
      render :action => 'new'
    end
  end

  def edit
    @proyecto = Proyecto.find(params[:id])
  end

  def update
    @proyecto = Proyecto.find(params[:id])
    if @proyecto.update_attributes(params[:proyecto])
      redirect_to @proyecto, :notice  => "Proyecto actualizado exitosamente"
    else
      render :action => 'edit'
    end
  end

  def destroy
    @proyecto = Proyecto.find(params[:id])
    @proyecto.destroy
    redirect_to proyectos_url, :notice => "Proyecto eliminado exitosamente"
  end
end
