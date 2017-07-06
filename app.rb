#encoding UTF8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'
 
                          # name - это имя парихмахера
def is_barber_exists? db,name  
                          # функция возвратит истину, если длина строки>0
  db.execute('select * from Barbers where name=?',[name]).length > 0
end  

def seed_db db,barbers
    barbers.each do |barber|
      if !is_barber_exists? db, barber
        db.execute 'insert into Barbers (Name) values (?)',[barber]
      end  
    end  
end

              #   SQLException
def get_db
  db = SQLite3::Database.new 'Barbershop.sqlite'  
 # db.results_as_hash = true   НЕ РАБОТАЕТ 
  return db
end

before do
  db = get_db
  @barbers = db.execute 'select * from Barbers'
end 


 configure do   # при  инициализации приложения
  db = get_db
#  db = SQLite3::Database.new 'Barbershop.sqlite' # убрала глобальную переменную
  
  db.execute 'CREATE TABLE IS NOT EXISTS
         "Users"
          ( 
          "id" INTEGER PRIMARY KEY AUTOINCREMENT,
          "Name" TEXT,
          "Phone" TEXT,
          "DateStamp" TEXT,
          "Barber" TEXT,
          "Color" INTEGER
           )'

  db.execute 'CREATE TABLE IS NOT EXISTS
              "Barbers"
              (
                "id" INTEGER PRIMARY KEY AUTOINCREMENT,
                "Name" TEXT
              )'  
   seed_db db,['Walter White','Jessie Pinkman','Gus Fring','Mike Richee']                  
 # enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Hello stranger'
  end
end

before '/secure/*' do
  unless session[:identity]
    session[:previous_url] = request.path
    @error = 'Sorry, you need to be logged in to visit ' + request.path
    halt erb(:login_form)
  end
end

get '/' do
  erb 'Can you handle a <a href="/secure/place">secret</a>?'
end

get '/about' do
   @error = 'something wrong'
   erb :about 
end  

get '/showusers' do
  db = get_db
  @results = db.execute 'select * from Users order by id desc'
  erb :showusers
end


get '/visit' do
   erb :visit 
end  

post '/visit' do
  @username = params[:username]
  @phone = params[:phone]
  @datetime = params[:datetime]
  @master = params[:master]
  @color = params[:color]

  f = File.open './public/users.txt','a' 
  f.write " Посетитель: #{@username},телефон: #{@phone}, время: #{@datetime}, мастер: #{@master}, цвет: #{@color}"
  f.close

  # хэш
  hh ={ :username => "Введите имя",
        :phone => "Введите номер телефона",
        :datetime => "Неправильная дата и время"}

# 1- variant @error = hh.select{|key,_| params[key] ==""}.values.join(",")
# if @error !=''
# return erb :visit
#  end

  # для каждой пары ключ=значение
  hh.each do |key,value|
    if params[key] == ''
      @error = hh[key] #переменной error присвоить сообщение об ошибке

      return erb :visit
    end  
  end      

  db = get_db
  db.execute 'insert into 
      Users
         (
          username, 
          phone, 
          datestamp,
          barber,
          color
          )
          values (?,?,?,?,?)',[@username, @phone, @datetime, @master, @color]

   

  erb " User: #{@username},phone: #{@phone}, time: #{@datetime}, master: #{@master}, color: #{@color}"
end  


get '/contacts' do
   erb :contacts 
end  

post '/contacts' do 
 # require 'pony'

  @username = params[:username]
  @email = params[:email]
  @comment = params[:comment]

  f = File.open './public/contacts.txt','a'
  f.write " Email: #{@email},сообщение: #{@comment}"
  
  mm = { :username => 'Введите свое имя',
         :email => 'Введите свой электронный ящик',
         :comment => 'Введите комментарий'}

#    @error = mm.select{|key,_| params[key]==""}.values.join(",")    

#    if @error != ''  do
#      return erb :contacts
#    end  

  mm.each do |key,value| 
    if  params[key] == ''
      @error = mm[value]
      return erb :contacts
    end  
  end  


  erb " User: #{@username},email: #{@email}, comment: #{@comment}}"

  
end  


get '/login/form' do
  erb :login_form
end

post '/login/attempt' do
  session[:identity] = params['username']
  where_user_came_from = session[:previous_url] || '/'
  redirect to where_user_came_from
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/secure/place' do
  erb 'This is a secret place that only <%=session[:identity]%> has access to!'
end
