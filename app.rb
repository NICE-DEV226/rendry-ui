require "sinatra/base"
require "sequel"
require "sqlite3"
require "erb"
require_relative "lib/ui"

class RubyUiApp < Sinatra::Base
  enable :method_override
  set :root, __dir__
  set :database, Sequel.sqlite(File.join(__dir__, "db", "development.sqlite3"))

  class Task < Sequel::Model(:tasks)
    plugin :timestamps, update_on_create: true

    def validate
      super
      errors.add(:title, "is required") if !title || title.strip.empty?
    end
  end

  configure do
    FileUtils.mkdir_p(File.join(root, "db"))
    database.create_table? :tasks do
      primary_key :id
      String :title, null: false
      Text :description
      TrueClass :completed, null: false, default: false
      DateTime :created_at
      DateTime :updated_at
    end
  end

  helpers do
    def h(value)
      Rack::Utils.escape_html(value.to_s)
    end

    def render_page(title, view, locals = {})
      erb view, layout: :layout, locals: locals.merge(page_title: title)
    end

    def task_params
      {
        title: params.fetch("title", "").strip,
        description: params.fetch("description", "").strip,
        completed: params["completed"] == "on"
      }
    end
  end

  get "/" do
    redirect "/tasks"
  end

  get "/tasks" do
    tasks = Task.order(Sequel.desc(:created_at)).all
    render_page("Task board", :index, tasks: tasks)
  end

  get "/tasks/new" do
    render_page("New task", :form, task: Task.new, form_title: "New task", form_action: "/tasks", submit_label: "Create task")
  end

  post "/tasks" do
    task = Task.new(task_params)
    if task.valid? && task.save
      redirect "/tasks/#{task.id}"
    else
      status 422
      render_page("New task", :form, task: task, form_title: "New task", form_action: "/tasks", submit_label: "Create task")
    end
  end

  get "/tasks/:id" do
    task = Task[params[:id]]
    halt 404, "Task not found" unless task
    render_page(task.title, :show, task: task)
  end

  get "/tasks/:id/edit" do
    task = Task[params[:id]]
    halt 404, "Task not found" unless task
    render_page("Edit task", :form, task: task, form_title: "Edit task", form_action: "/tasks/#{task.id}", submit_label: "Save changes")
  end

  patch "/tasks/:id" do
    task = Task[params[:id]]
    halt 404, "Task not found" unless task
    if task.update(task_params) && task.valid?
      redirect "/tasks/#{task.id}"
    else
      status 422
      render_page("Edit task", :form, task: task, form_title: "Edit task", form_action: "/tasks/#{task.id}", submit_label: "Save changes")
    end
  end

  delete "/tasks/:id" do
    task = Task[params[:id]]
    halt 404, "Task not found" unless task
    task.destroy
    redirect "/tasks"
  end
end
